module Web3.Eth.Tx.Sentry exposing (..)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Value, Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Http
import Process
import Web3.Eth as Eth
import Web3.Eth exposing (RpcRequest, buildRequest)
import Web3.Types exposing (..)
import Web3.Encode as Encode


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


{-| Look into the errors this might cause, some kind of cleanup process should probably occur on changing a node.
-}
changeNode : String -> TxSentry msg -> TxSentry msg
changeNode newNodePath (TxSentry txSentry) =
    TxSentry { txSentry | nodePath = newNodePath }


type TxSentry msg
    = TxSentry
        { inPort : (Value -> Msg) -> Sub Msg
        , outPort : Value -> Cmd Msg
        , tagger : Msg -> msg
        , nodePath : String
        , txs : Dict Int (TxState msg)
        , debug : Bool
        , ref : Int
        }


type TxStatus
    = Signing Send
    | Signed TxId
    | Sent Tx
    | Mined TxReceipt


type alias TxState msg =
    { params : Send
    , txTagger : Tx -> msg
    , receiptTagger : Maybe (TxReceipt -> msg)
    , status : TxStatus
    }



--- UPDATE


type Msg
    = NoOp
    | TxSigned TxIdResponse
    | TxSent Int (Result Http.Error Tx)
    | TxMined { ref : Int, txReceipt : TxReceipt }


update : Msg -> TxSentry msg -> ( TxSentry msg, Cmd msg )
update msg (TxSentry sentry) =
    case msg of
        TxSigned { ref, txId } ->
            case Dict.get ref sentry.txs of
                Just txState ->
                    ( TxSentry { sentry | txs = Dict.update ref (txStatusSigned txId) sentry.txs }
                    , Cmd.map sentry.tagger <|
                        Task.attempt (TxSent ref)
                            (Process.sleep 500 |> Task.andThen (\_ -> Eth.getTransactionByHash sentry.nodePath txId))
                    )

                Nothing ->
                    ( TxSentry sentry
                    , Cmd.none
                    )

        TxSent ref result ->
            case result of
                Ok tx ->
                    case Dict.get ref sentry.txs of
                        Just txState ->
                            ( TxSentry { sentry | txs = Dict.update ref (txStatusSent tx) sentry.txs }
                            , Task.perform txState.txTagger (Task.succeed tx)
                              -- , Cmd.none
                            )

                        Nothing ->
                            ( TxSentry sentry, Cmd.none )

                Err error ->
                    ( TxSentry sentry, Cmd.none )

        _ ->
            ( TxSentry sentry
            , Cmd.none
            )



{- Dict Update Helpers -}


txStatusSigned : TxId -> Maybe (TxState msg) -> Maybe (TxState msg)
txStatusSigned txId =
    Maybe.map (\txState -> { txState | status = Signed txId })


txStatusSent : Tx -> Maybe (TxState msg) -> Maybe (TxState msg)
txStatusSent tx =
    Maybe.map (\txState -> { txState | status = Sent tx })



-- API


send : Send -> (Tx -> msg) -> TxSentry msg -> ( TxSentry msg, Cmd msg )
send send onReceiveTx (TxSentry sentry) =
    let
        newTxs =
            Dict.insert sentry.ref (newTxState send Nothing onReceiveTx) sentry.txs
    in
        (TxSentry { sentry | txs = newTxs, ref = sentry.ref + 1 })
            ! [ Cmd.map sentry.tagger <| sentry.outPort (encodeTxData sentry.ref send) ]


listen : TxSentry msg -> Sub msg
listen (TxSentry sentry) =
    Sub.map sentry.tagger (sentry.inPort decodeTxData)


{-| -}
withDebug : TxSentry msg -> TxSentry msg
withDebug (TxSentry sentry) =
    TxSentry { sentry | debug = True }



--


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


txIdResponseDecoder : Decoder TxIdResponse
txIdResponseDecoder =
    Decode.map2 (\ref txId -> { ref = ref, txId = txId })
        (Decode.field "ref" Decode.int)
        (Decode.field "txId" (Decode.map TxId Decode.string))


type alias TxIdResponse =
    { ref : Int, txId : TxId }


newTxState : Send -> Maybe (TxReceipt -> msg) -> (Tx -> msg) -> TxState msg
newTxState send receiptTagger txTagger =
    { params = send
    , txTagger = txTagger
    , receiptTagger = receiptTagger
    , status = Signing send
    }
