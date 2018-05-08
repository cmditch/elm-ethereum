module Eth.Sentry.Tx
    exposing
        ( TxSentry
        , Msg
        , update
        , init
        , listen
        , send
        , sendWithReceipt
        , CustomSend
        , TxTracker
        , customSend
        , withDebug
        , changeNode
        )

{-|


# Core

@docs TxSentry, Msg, update, init, listen


# Send Txs

@docs send, sendWithReceipt


# Custom Send

@docs CustomSend, TxTracker, customSend


# Utils

@docs withDebug, changeNode

-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Value, Decoder)
import Json.Encode as Encode
import Maybe.Extra as Maybe
import Task exposing (Task)
import Http
import Process
import Eth
import Eth.Encode as Encode
import Eth.Decode as Decode
import Eth.Types exposing (..)
import Eth.Utils exposing (Retry, retry)


{-| -}
type TxSentry msg
    = TxSentry
        { inPort : (Value -> Msg) -> Sub Msg
        , outPort : Value -> Cmd Msg
        , nodePath : HttpProvider
        , tagger : Msg -> msg
        , txs : Dict Int (TxState msg)
        , debug : Bool
        , ref : Int
        }


{-| -}
init : ( Value -> Cmd Msg, (Value -> Msg) -> Sub Msg ) -> (Msg -> msg) -> HttpProvider -> TxSentry msg
init ( outPort, inPort ) tagger nodePath =
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
    send_ { onSign = Nothing, onBroadcast = Just onBroadcast, onMined = Just ( onMined, Nothing ) } txParams sentry


{-|

    onSign : Message after metamask/wallet has signed tx and returned tx hash
    onBroadcast : Message after tx is confirmed sitting in tx queue on the node
    onMined : ( message after tx is mined,
                (number of blocks deep to watch tx, message on each mined block after tx is sent - stops sending messages when first tuple value is reached)
              )
-}
type alias CustomSend msg =
    { onSign : Maybe (TxHash -> msg)
    , onBroadcast : Maybe (Tx -> msg)
    , onMined : Maybe ( TxReceipt -> msg, Maybe ( Int, TxTracker -> msg ) )
    }


{-| For checking whether a tx has reached a certain block depth (# of confirmations) in a customSend
-}
type alias TxTracker =
    { currentDepth : Int
    , minedInBlock : Int
    , stopWatchingAtBlock : Int
    , lastCheckedBlock : Int
    , txHash : TxHash
    , doneWatching : Bool
    , reOrg : Bool
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
changeNode : HttpProvider -> TxSentry msg -> TxSentry msg
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
    , onMinedTagger : Maybe ( TxReceipt -> msg, Maybe ( Int, TxTracker -> msg ) )
    , status : TxStatus
    }



-- UPDATE


{-| -}
type Msg
    = NoOp
    | TxSigned { ref : Int, txHash : TxHash }
    | TxSent Int (Result Http.Error Tx)
    | TxMined Int (Result Http.Error TxReceipt)
    | TrackTx Int TxTracker (Result Http.Error Int)
    | ErrorDecoding String


{-| -}
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
                            if Maybe.isJust txState.onBroadcastTagger || Maybe.isJust txState.onMinedTagger then
                                Task.attempt (TxSent ref) (pollTxBroadcast sentry.nodePath txHash)
                                    |> Cmd.map sentry.tagger
                            else
                                Cmd.none
                    in
                        ( TxSentry { sentry | txs = Dict.update ref (txStatusSigned txHash) sentry.txs }
                        , Cmd.batch
                            [ txSignedCmd
                            , txBroadcastCmd
                            ]
                        )

                Nothing ->
                    ( TxSentry sentry, Cmd.none )

        TxSent ref (Ok tx) ->
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
                                        Task.attempt (TxMined ref)
                                            (pollTxReceipt sentry.nodePath tx.hash)
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

        TxSent ref (Err error) ->
            let
                _ =
                    debugHelp sentry (log.broadcastError error)
            in
                ( TxSentry sentry, Cmd.none )

        TxMined ref (Ok txReceipt) ->
            let
                _ =
                    debugHelp sentry (log.mined txReceipt ref)
            in
                case Dict.get ref sentry.txs of
                    Just txState ->
                        let
                            cmdIfMined =
                                case txState.onMinedTagger of
                                    Just ( txReceiptToMsg, Nothing ) ->
                                        Task.perform txReceiptToMsg (Task.succeed txReceipt)

                                    Just ( txReceiptToMsg, Just ( depthParam, blockDepthToMsg ) ) ->
                                        let
                                            txTracker =
                                                { currentDepth = 1
                                                , minedInBlock = txReceipt.blockNumber
                                                , stopWatchingAtBlock = txReceipt.blockNumber + (depthParam - 1)
                                                , lastCheckedBlock = txReceipt.blockNumber
                                                , txHash = txReceipt.hash
                                                , doneWatching = False
                                                , reOrg = False
                                                }
                                        in
                                            Cmd.batch
                                                [ Task.attempt (TrackTx ref txTracker) (Eth.getBlockNumber sentry.nodePath)
                                                    |> Cmd.map sentry.tagger
                                                , Task.perform txReceiptToMsg (Task.succeed txReceipt)
                                                , Task.perform blockDepthToMsg (Task.succeed txTracker)
                                                ]

                                    Nothing ->
                                        Cmd.none
                        in
                            ( TxSentry { sentry | txs = Dict.update ref (txStatusMined txReceipt) sentry.txs }
                            , cmdIfMined
                            )

                    Nothing ->
                        ( TxSentry sentry, Cmd.none )

        TxMined _ (Err error) ->
            let
                _ =
                    debugHelp sentry (log.minedError error)
            in
                ( TxSentry sentry, Cmd.none )

        TrackTx ref txTracker (Ok newBlockNum) ->
            if newBlockNum == txTracker.stopWatchingAtBlock then
                -- if block depth is reached, send DeepEnough msg
                case getTxTrackerToMsg sentry.txs ref of
                    Just blockDepthToMsg ->
                        let
                            newTxTracker =
                                { txTracker
                                    | lastCheckedBlock = newBlockNum
                                    , currentDepth = (newBlockNum - txTracker.minedInBlock) + 1
                                    , doneWatching = True
                                }
                        in
                            ( TxSentry sentry
                            , Task.perform blockDepthToMsg
                                (Eth.getTxReceipt sentry.nodePath txTracker.txHash
                                    |> Task.andThen (\_ -> Task.succeed newTxTracker)
                                    |> Task.onError
                                        (\_ ->
                                            (Task.succeed <|
                                                Debug.log
                                                    "TxTracker - Possible Chain ReOrg"
                                                    { newTxTracker | reOrg = True }
                                            )
                                        )
                                )
                            )

                    Nothing ->
                        ( TxSentry sentry, Cmd.none )
            else if newBlockNum == txTracker.lastCheckedBlock then
                -- else keep polling for new block
                ( TxSentry sentry
                , Task.attempt (TrackTx ref txTracker)
                    (Process.sleep 2000
                        |> Task.andThen (\_ -> Eth.getBlockNumber sentry.nodePath)
                    )
                    |> Cmd.map sentry.tagger
                )
            else
                -- If the newly polled blockNumber /= the previously polled blockNumber,
                -- let the user know a new blockDepth has been reached.
                case getTxTrackerToMsg sentry.txs ref of
                    Just blockDepthToMsg ->
                        let
                            newTxTracker =
                                { txTracker
                                    | lastCheckedBlock = newBlockNum
                                    , currentDepth = (newBlockNum - txTracker.minedInBlock) + 1
                                }
                        in
                            ( TxSentry sentry
                            , Cmd.batch
                                [ Task.attempt (TrackTx ref newTxTracker)
                                    (Process.sleep 2000
                                        |> Task.andThen (\_ -> Eth.getBlockNumber sentry.nodePath)
                                    )
                                    |> Cmd.map sentry.tagger
                                , Task.perform blockDepthToMsg (Task.succeed newTxTracker)
                                ]
                            )

                    Nothing ->
                        ( TxSentry sentry, Cmd.none )

        TrackTx ref _ (Err error) ->
            let
                _ =
                    Debug.log "TxTracker" ("Error getting latest block. Info: " ++ toString error)
            in
                ( TxSentry sentry, Cmd.none )

        ErrorDecoding error ->
            let
                _ =
                    debugHelp sentry (log.decodeError error)
            in
                ( TxSentry sentry, Cmd.none )



-- Chain Helpers


pollTxReceipt : HttpProvider -> TxHash -> Task Http.Error TxReceipt
pollTxReceipt nodePath txHash =
    let
        _ =
            Debug.log "pollTxReceipt" "Watching Transaction for first confirmation"
    in
        Eth.getTxReceipt nodePath txHash
            -- polls for 5 minutes every 5 seconds for the first confirmation
            |> retry { attempts = 60, sleep = 5 }


pollTxBroadcast : HttpProvider -> TxHash -> Task Http.Error Tx
pollTxBroadcast nodePath txHash =
    Process.sleep 250
        |> Task.andThen
            (\_ ->
                Eth.getTx nodePath txHash
                    -- polls for 30 seconds every 1 second
                    |> retry { attempts = 30, sleep = 1 }
            )



{- Dict Helpers -}


txStatusSigned : TxHash -> Maybe (TxState msg) -> Maybe (TxState msg)
txStatusSigned txHash =
    Maybe.map (\txState -> { txState | status = Signed txHash })


txStatusSent : Tx -> Maybe (TxState msg) -> Maybe (TxState msg)
txStatusSent tx =
    Maybe.map (\txState -> { txState | status = Sent tx })


txStatusMined : TxReceipt -> Maybe (TxState msg) -> Maybe (TxState msg)
txStatusMined txReceipt =
    Maybe.map (\txState -> { txState | status = Mined txReceipt })


getTxTrackerToMsg : Dict Int (TxState msg) -> Int -> Maybe (TxTracker -> msg)
getTxTrackerToMsg txs ref =
    Dict.get ref txs
        |> Maybe.andThen (\txState -> txState.onMinedTagger)
        |> Maybe.andThen (\onMined -> Tuple.second onMined)
        |> Maybe.map (\( _, txTracker ) -> txTracker)



-- Decoders/Encoders


encodeTxData : Int -> Send -> Value
encodeTxData ref send =
    Encode.object
        [ ( "ref", Encode.int ref )
        , ( "txParams", Encode.txSend send )
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
