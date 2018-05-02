module Web3.Eth.TxSentry
    exposing
        ( TxSentry
        , init
        , listen
        , send
        , sendWithReceipt
        , CustomSend
        , customSend
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


{-| -}
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


{-| -}
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


{-| -}
listen : TxSentry msg -> Sub msg
listen (TxSentry sentry) =
    Sub.map sentry.tagger (sentry.inPort decodeTxData)


{-| -}
send : (Tx -> msg) -> Send -> TxSentry msg -> ( TxSentry msg, Cmd msg )
send onBroadcast txParams sentry =
    send_ { onSign = Nothing, onBroadcast = Just onBroadcast, onMined = Nothing } txParams sentry


{-| -}
sendWithReceipt : (Tx -> msg) -> (TxReceipt -> msg) -> Send -> TxSentry msg -> ( TxSentry msg, Cmd msg )
sendWithReceipt onBroadcast onMined txParams sentry =
    send_ { onSign = Nothing, onBroadcast = Just onBroadcast, onMined = Just onMined } txParams sentry


{-| -}
type alias CustomSend msg =
    { onSign : Maybe (TxHash -> msg)
    , onBroadcast : Maybe (Tx -> msg)
    , onMined : Maybe (TxReceipt -> msg)
    }


{-| -}
customSend : CustomSend msg -> Send -> TxSentry msg -> ( TxSentry msg, Cmd msg )
customSend =
    send_


{-| -}
withDebug : TxSentry msg -> TxSentry msg
withDebug (TxSentry sentry) =
    TxSentry { sentry | debug = True }


{-| Look into the errors this might cause, some kind of cleanup process should probably occur on changing a node.
-}
changeNode : String -> TxSentry msg -> TxSentry msg
changeNode newNodePath (TxSentry sentry) =
    let
        _ =
            debugHelp sentry (log.nodeChanged newNodePath)
    in
        TxSentry { sentry | nodePath = newNodePath }



-- INTERNAL


send_ : CustomSend msg -> Send -> TxSentry msg -> ( TxSentry msg, Cmd msg )
send_ sendParams txParams (TxSentry sentry) =
    let
        newTxs =
            Dict.insert sentry.ref (newTxState txParams sendParams) sentry.txs
    in
        (TxSentry { sentry | txs = newTxs, ref = sentry.ref + 1 })
            ! [ Cmd.map sentry.tagger <| sentry.outPort (encodeTxData sentry.ref txParams) ]


type TxStatus
    = Signing Send
    | Signed TxHash
    | Sent Tx
    | Mined TxReceipt


type alias TxState msg =
    { params : Send
    , onSignedTagger : Maybe (TxHash -> msg)
    , onBroadcastTagger : Maybe (Tx -> msg)
    , onMinedTagger : Maybe (TxReceipt -> msg)
    , status : TxStatus
    }



-- UPDATE


type Msg
    = NoOp
    | ErrorDecoding String
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
                    let
                        _ =
                            debugHelp sentry (log.signed txHash ref)

                        txSignedCmd =
                            case txState.onSignedTagger of
                                Just txHashToMsg ->
                                    Task.perform txHashToMsg (Task.succeed txHash)

                                Nothing ->
                                    Cmd.none

                        txBroadcastCmd =
                            Cmd.map sentry.tagger <|
                                Task.attempt (TxSent ref) (pollTxBroadcast sentry.nodePath txHash)
                    in
                        ( TxSentry { sentry | txs = Dict.update ref (txStatusSigned txHash) sentry.txs }
                        , Cmd.batch
                            [ txSignedCmd
                            , txBroadcastCmd
                            ]
                        )

                Nothing ->
                    ( TxSentry sentry, Cmd.none )

        TxSent ref result ->
            case result of
                Ok tx ->
                    let
                        _ =
                            debugHelp sentry (log.broadcast tx ref)
                    in
                        case Dict.get ref sentry.txs of
                            Just txState ->
                                let
                                    txBroadcastCmd =
                                        case txState.onBroadcastTagger of
                                            Just txToMsg ->
                                                Task.perform txToMsg (Task.succeed tx)

                                            Nothing ->
                                                Cmd.none

                                    txMinedCmd =
                                        case txState.onMinedTagger of
                                            Just _ ->
                                                Task.attempt (TxMined ref) (pollTxReceipt sentry.nodePath tx.hash)
                                                    |> Cmd.map sentry.tagger

                                            Nothing ->
                                                Cmd.none
                                in
                                    ( TxSentry { sentry | txs = Dict.update ref (txStatusSent tx) sentry.txs }
                                    , Cmd.batch
                                        [ txBroadcastCmd
                                        , txMinedCmd
                                        ]
                                    )

                            Nothing ->
                                ( TxSentry sentry, Cmd.none )

                Err error ->
                    let
                        _ =
                            debugHelp sentry (log.broadcastError error)
                    in
                        ( TxSentry sentry, Cmd.none )

        TxMined ref result ->
            case result of
                Ok txReceipt ->
                    let
                        _ =
                            debugHelp sentry (log.mined txReceipt ref)
                    in
                        case Dict.get ref sentry.txs of
                            Just txState ->
                                let
                                    cmdIfMined =
                                        case txState.onMinedTagger of
                                            Just txReceiptToMsg ->
                                                Task.perform txReceiptToMsg (Task.succeed txReceipt)

                                            Nothing ->
                                                Cmd.none
                                in
                                    ( TxSentry { sentry | txs = Dict.update ref (txStatusMined txReceipt) sentry.txs }
                                    , cmdIfMined
                                    )

                            Nothing ->
                                ( TxSentry sentry, Cmd.none )

                Err error ->
                    let
                        _ =
                            debugHelp sentry (log.minedError error)
                    in
                        ( TxSentry sentry, Cmd.none )

        ErrorDecoding error ->
            let
                _ =
                    debugHelp sentry (log.decodeError error)
            in
                ( TxSentry sentry, Cmd.none )


pollTxReceipt : String -> TxHash -> Task Http.Error TxReceipt
pollTxReceipt nodePath txHash =
    Eth.getTxReceipt nodePath txHash
        -- polls for 5 minutes every 5 seconds
        |> retry { attempts = 60, sleep = 5 }


pollTxBroadcast : String -> TxHash -> Task Http.Error Tx
pollTxBroadcast nodePath txHash =
    Process.sleep 250
        |> Task.andThen
            (\_ ->
                Eth.getTx nodePath txHash
                    -- polls for 30 seconds every 1 second
                    |> retry { attempts = 30, sleep = 1 }
            )



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
            ErrorDecoding error


txIdResponseDecoder : Decoder { ref : Int, txHash : TxHash }
txIdResponseDecoder =
    Decode.map2 (\ref txHash -> { ref = ref, txHash = txHash })
        (Decode.field "ref" Decode.int)
        (Decode.field "txHash" Decode.txHash)


newTxState : Send -> CustomSend msg -> TxState msg
newTxState send { onSign, onBroadcast, onMined } =
    { params = send
    , onSignedTagger = onSign
    , onBroadcastTagger = onBroadcast
    , onMinedTagger = onMined
    , status = Signing send
    }



-- Logger


debugHelp sentry logger =
    if sentry.debug then
        logger
    else
        ""


log =
    { signed = \txHash ref -> Debug.log "TxSentry - Tx Signed" (toString txHash ++ " (dict-ref: " ++ toString ref ++ ")")
    , broadcast = \tx ref -> Debug.log "TxSentry - Tx Broadcast" (toString tx ++ " (dict-ref: " ++ toString ref ++ ")")
    , broadcastError = \error -> Debug.log "TxSentry - Error Broadcasting" (toString error)
    , mined = \txReceipt ref -> Debug.log "TxSentry - Tx Mined" (toString txReceipt ++ " (dict-ref: " ++ toString ref ++ ")")
    , minedError = \error -> Debug.log "TxSentry - Error Mining" (toString error)
    , nodeChanged = \newNodePath -> Debug.log "TxSentry - Nodepath changed" (toString newNodePath)
    , decodeError =
        \error ->
            Debug.log "Error decoding"
                (error ++ " (Problem is likely in your JS port code. Make sure you're sending me a value that looks like this { ref: Int, txHash: TxHash }")
    }
