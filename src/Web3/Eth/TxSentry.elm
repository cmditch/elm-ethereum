module Web3.Eth.TxSentry
    exposing
        ( TxSentry
        , init
        , send
        , sendWithReceipt
        , listen
        , withDebug
        , changeNode
        )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Value, Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Http
import Process
import Web3.Eth as Eth
import Web3.Eth.Encode as Encode
import Web3.Eth.Decode as Decode
import Web3.Eth.Types exposing (..)
import Web3.Utils exposing (Retry, retry)


type TxSentry msg
    = TxSentry
        { inPort : (Value -> Msg) -> Sub Msg
        , outPort : Value -> Cmd Msg
        , nodePath : String
        , tagger : Msg -> msg
        , txs : Dict Int (TxState msg)
        , debug : Bool
        , ref : Int
        }


init : ( (Value -> Msg) -> Sub Msg, Value -> Cmd Msg ) -> (Msg -> msg) -> String -> TxSentry msg
init ( inPort, outPort ) tagger nodePath =
    TxSentry
        { inPort = inPort
        , outPort = outPort
        , nodePath = nodePath
        , tagger = tagger
        , txs = Dict.empty
        , debug = False
        , ref = 1
        }


send : Send -> (Tx -> msg) -> TxSentry msg -> ( TxSentry msg, Cmd msg )
send txParams onReceiveTx sentry =
    send_ txParams onReceiveTx Nothing sentry


sendWithReceipt : Send -> (Tx -> msg) -> (TxReceipt -> msg) -> TxSentry msg -> ( TxSentry msg, Cmd msg )
sendWithReceipt txParams onReceiveTx onReceiveTxReceipt sentry =
    send_ txParams onReceiveTx (Just onReceiveTxReceipt) sentry


send_ : Send -> (Tx -> msg) -> Maybe (TxReceipt -> msg) -> TxSentry msg -> ( TxSentry msg, Cmd msg )
send_ txParams onReceiveTx onReceiveTxReceipt (TxSentry sentry) =
    let
        newTxs =
            Dict.insert sentry.ref (newTxState txParams onReceiveTxReceipt onReceiveTx) sentry.txs
    in
        (TxSentry { sentry | txs = newTxs, ref = sentry.ref + 1 })
            ! [ Cmd.map sentry.tagger <| sentry.outPort (encodeTxData sentry.ref txParams) ]


listen : TxSentry msg -> Sub msg
listen (TxSentry sentry) =
    Sub.map sentry.tagger (sentry.inPort decodeTxData)


{-| -}
withDebug : TxSentry msg -> TxSentry msg
withDebug (TxSentry sentry) =
    TxSentry { sentry | debug = True }


{-| Look into the errors this might cause, some kind of cleanup process should probably occur on changing a node.
-}
changeNode : String -> TxSentry msg -> TxSentry msg
changeNode newNodePath (TxSentry txSentry) =
    TxSentry { txSentry | nodePath = newNodePath }



-- Internal


type TxStatus
    = Signing Send
    | Signed TxHash
    | Sent Tx
    | Mined TxReceipt


type alias TxState msg =
    { params : Send
    , txTagger : Tx -> msg
    , receiptTagger : Maybe (TxReceipt -> msg)
    , status : TxStatus
    }


type Msg
    = NoOp
    | TxSigned { ref : Int, txHash : TxHash }
    | TxSent Int (Result Http.Error Tx)
    | TxMined Int (Result Http.Error TxReceipt)


update : Msg -> TxSentry msg -> ( TxSentry msg, Cmd msg )
update msg (TxSentry sentry) =
    case msg of
        NoOp ->
            ( TxSentry sentry, Cmd.none )

        TxSigned { ref, txHash } ->
            case Dict.get ref sentry.txs of
                Just txState ->
                    ( TxSentry { sentry | txs = Dict.update ref (txStatusSigned txHash) sentry.txs }
                    , Cmd.map sentry.tagger <|
                        Task.attempt (TxSent ref)
                            (Process.sleep 500 |> Task.andThen (\_ -> Eth.getTx sentry.nodePath txHash))
                    )

                Nothing ->
                    ( TxSentry sentry, Cmd.none )

        TxSent ref result ->
            case result of
                Ok tx ->
                    case Dict.get ref sentry.txs of
                        Just txState ->
                            let
                                watchForConfirmation =
                                    case txState.receiptTagger of
                                        Nothing ->
                                            Cmd.none

                                        Just _ ->
                                            Task.attempt (TxMined ref) (pollTxReceipt sentry.nodePath tx.hash)
                                                |> Cmd.map sentry.tagger
                            in
                                ( TxSentry { sentry | txs = Dict.update ref (txStatusSent tx) sentry.txs }
                                , Cmd.batch
                                    [ Task.perform txState.txTagger (Task.succeed tx)
                                    , watchForConfirmation
                                    ]
                                )

                        Nothing ->
                            ( TxSentry sentry, Cmd.none )

                Err error ->
                    ( TxSentry sentry, Cmd.none )

        TxMined ref result ->
            case result of
                Ok txReceipt ->
                    case Dict.get ref sentry.txs of
                        Just txState ->
                            let
                                cmdIfMined =
                                    case txState.receiptTagger of
                                        Nothing ->
                                            Cmd.none

                                        Just receiptTagger ->
                                            Task.perform receiptTagger (Task.succeed txReceipt)
                            in
                                ( TxSentry { sentry | txs = Dict.update ref (txStatusMined txReceipt) sentry.txs }
                                , cmdIfMined
                                )

                        Nothing ->
                            ( TxSentry sentry, Cmd.none )

                Err error ->
                    ( TxSentry sentry, Cmd.none )


pollTxReceipt : String -> TxHash -> Task Http.Error TxReceipt
pollTxReceipt nodePath txHash =
    Eth.getTxReceipt nodePath txHash
        -- polls for 5 minutes every 5 seconds
        |> retry { attempts = 60, sleep = 5 }



{- Dict Update Helpers -}


txStatusSigned : TxHash -> Maybe (TxState msg) -> Maybe (TxState msg)
txStatusSigned txHash =
    Maybe.map (\txState -> { txState | status = Signed txHash })


txStatusSent : Tx -> Maybe (TxState msg) -> Maybe (TxState msg)
txStatusSent tx =
    Maybe.map (\txState -> { txState | status = Sent tx })


txStatusMined : TxReceipt -> Maybe (TxState msg) -> Maybe (TxState msg)
txStatusMined txReceipt =
    Maybe.map (\txState -> { txState | status = Mined txReceipt })



-- Decoders/Encoders


encodeTxData : Int -> Send -> Value
encodeTxData ref send =
    Encode.object
        [ ( "ref", Encode.int ref )
        , ( "txParams", Encode.sendParams send )
        ]


decodeTxData : Value -> Msg
decodeTxData val =
    case Decode.decodeValue txIdResponseDecoder val of
        Ok result ->
            TxSigned result

        Err error ->
            NoOp


txIdResponseDecoder : Decoder { ref : Int, txHash : TxHash }
txIdResponseDecoder =
    Decode.map2 (\ref txHash -> { ref = ref, txHash = txHash })
        (Decode.field "ref" Decode.int)
        (Decode.field "txHash" Decode.txHash)


newTxState : Send -> Maybe (TxReceipt -> msg) -> (Tx -> msg) -> TxState msg
newTxState send receiptTagger txTagger =
    { params = send
    , txTagger = txTagger
    , receiptTagger = receiptTagger
    , status = Signing send
    }
