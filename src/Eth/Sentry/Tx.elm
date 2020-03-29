module Eth.Sentry.Tx exposing
    ( TxSentry, Msg, update, init, OutPort, InPort, listen
    , send, sendWithReceipt
    , CustomSend, TxTracker, customSend
    , changeNode
    )

{-|


# Core

@docs TxSentry, Msg, update, init, OutPort, InPort, listen


# Send Txs

@docs send, sendWithReceipt


# Custom Send

@docs CustomSend, TxTracker, customSend


# Utils

@docs changeNode

-}

import Dict exposing (Dict)
import Eth
import Eth.Decode as Decode
import Eth.Types exposing (..)
import Eth.Utils exposing (Retry, retry)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Maybe.Extra as Maybe
import Process
import Task exposing (Task)


{-| -}
type TxSentry msg
    = TxSentry
        { inPort : InPort
        , outPort : OutPort
        , nodePath : HttpProvider
        , tagger : Msg -> msg
        , txs : Dict Int (TxState msg)
        , ref : Int

        -- , debug : Maybe (String -> a -> a)
        }


{-| Replace all `Result String x` with `Result TxSentry.Error x`

Create `Http.Error -> TxSentry.Error` Function

Fix JS code to catch and cast appropriate errors.

-}
type Error
    = Error String
    | UserRejected
    | Web3Undefined
    | NetworkError


{-| -}
init : ( OutPort, InPort ) -> (Msg -> msg) -> HttpProvider -> TxSentry msg
init ( outPort, inPort ) tagger nodePath =
    TxSentry
        { inPort = inPort
        , outPort = outPort
        , nodePath = nodePath
        , tagger = tagger
        , txs = Dict.empty
        , ref = 1

        -- , debug = Nothing
        }


{-| The `txOut` port.
Where information from your elm app is sent OUT to javascript land.
Used for sending `Send` Tx parameters to Metamask, or other wallets.

    port txOut : Value -> Cmd msg

-}
type alias OutPort =
    Value -> Cmd Msg


{-| The `txIn` subscription.
Where information from the outside comes IN to your elm app.
Used for getting the TxHash response from Metamask, or other wallets.

     port txIn : (Value -> msg) -> Sub msg

-}
type alias InPort =
    (Value -> Msg) -> Sub Msg


{-| -}
listen : TxSentry msg -> Sub msg
listen (TxSentry sentry) =
    Sub.map sentry.tagger (sentry.inPort decodeTxData)


{-| -}
send : (Result String Tx -> msg) -> TxSentry msg -> Send -> ( TxSentry msg, Cmd msg )
send onBroadcast sentry txParams =
    send_ sentry { onSign = Nothing, onBroadcast = Just onBroadcast, onMined = Nothing } txParams


{-| -}
sendWithReceipt : (Result String Tx -> msg) -> (Result String TxReceipt -> msg) -> TxSentry msg -> Send -> ( TxSentry msg, Cmd msg )
sendWithReceipt onBroadcast onMined sentry txParams =
    send_ sentry { onSign = Nothing, onBroadcast = Just onBroadcast, onMined = Just ( onMined, Nothing ) } txParams


{-|

    onSign : Message after metamask/wallet has signed tx and returned tx hash
    onBroadcast : Message after tx is confirmed sitting in tx queue on the node
    onMined : ( message after tx is mined,
                (number of blocks deep to watch tx, message on each mined block after tx is sent - stops sending messages when first tuple value is reached)
              )

-}
type alias CustomSend msg =
    { onSign : Maybe (Result String TxHash -> msg)
    , onBroadcast : Maybe (Result String Tx -> msg)
    , onMined : Maybe ( Result String TxReceipt -> msg, Maybe { confirmations : Int, toMsg : TxTracker -> msg } )
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
customSend : TxSentry msg -> CustomSend msg -> Send -> ( TxSentry msg, Cmd msg )
customSend =
    send_



-- {-| -}
-- withDebug : (String -> a -> a) -> TxSentry msg -> TxSentry msg
-- withDebug logFunc (TxSentry sentry) =
--     TxSentry { sentry | debug = Just logFunc }


{-| Look into the errors this might cause,
some kind of cleanup process should probably occur on changing a node.
-}
changeNode : HttpProvider -> TxSentry msg -> TxSentry msg
changeNode newNodePath (TxSentry sentry) =
    -- let
    --     _ =
    --         debugHelp sentry.debug log.nodeChanged newNodePath
    -- in
    TxSentry { sentry | nodePath = newNodePath }



-- INTERNAL
-- send_ : TxSentry msg -> CustomSend msg -> Send -> ( TxSentry msg, Cmd msg )
-- send_ (TxSentry sentry) sendParams txParams =
--     case Encode.encodeSend txParams of
--         Ok txParamVal ->
--             let
--                 newTxs =
--                     Dict.insert sentry.ref (newTxState txParams sendParams) sentry.txs
--             in
--             ( TxSentry { sentry | txs = newTxs, ref = sentry.ref + 1 }
--             , Cmd.map sentry.tagger <| sentry.outPort (encodeTxData sentry.ref txParamVal)
--             )
--         Err err ->
--             let
--                 sendError : Maybe (Result String a -> msg) -> Cmd msg
--                 sendError maybeTagger =
--                     Maybe.map (\tagger -> Task.perform tagger (Task.succeed <| Err err)) maybeTagger
--                         |> Maybe.withDefault Cmd.none
--             in
--             ( TxSentry sentry
--             , Cmd.batch
--                 [ sendError sendParams.onSignedTagger
--                 , sendError sendParams.onBroadcastTagger
--                 , sendError sendParams.onMinedTagger
--                 ]
--             )


send_ : TxSentry msg -> CustomSend msg -> Send -> ( TxSentry msg, Cmd msg )
send_ (TxSentry sentry) customSendParams txParams =
    let
        txParamsVal =
            Eth.encodeSend txParams

        newTxs =
            Dict.insert sentry.ref (newTxState txParams customSendParams) sentry.txs
    in
    ( TxSentry { sentry | txs = newTxs, ref = sentry.ref + 1 }
    , Cmd.map sentry.tagger <| sentry.outPort (encodeTxData sentry.ref txParamsVal)
    )


type TxStatus
    = Signing Send
    | Signed TxHash
    | Sent Tx
    | Mined TxReceipt
    | Failed Error


type alias TxState msg =
    { params : Send
    , onSignedTagger : Maybe (Result String TxHash -> msg)
    , onBroadcastTagger : Maybe (Result String Tx -> msg)
    , onMinedTagger : Maybe ( Result String TxReceipt -> msg, Maybe { confirmations : Int, toMsg : TxTracker -> msg } )
    , status : TxStatus
    }



-- UPDATE


{-| -}
type Msg
    = NoOp
    | TxSigned Int (Result String TxHash)
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

        TxSigned ref txHashResult ->
            -- When a Send (Tx params) has been sucessfully signed by wallet,
            -- and an "onSignedTagger" was provided by the user,
            -- Msg User Land accordingly.
            case Dict.get ref sentry.txs of
                Just txState ->
                    let
                        -- _ =
                        --     debugHelp sentry.debug log.signed (toString txHashResult)
                        txSignedCmd =
                            case txState.onSignedTagger of
                                Just txHashToMsg ->
                                    Task.perform txHashToMsg (Task.succeed txHashResult)

                                Nothing ->
                                    Cmd.none

                        -- Send Err's to any other callbacks the user might have provided
                        failOtherCallbacks error =
                            case ( txState.onSignedTagger, txState.onBroadcastTagger, txState.onMinedTagger ) of
                                ( Just _, _, _ ) ->
                                    Cmd.none

                                ( _, Just txToMsg, _ ) ->
                                    Task.perform txToMsg (Task.succeed (Err error))

                                ( _, _, Just ( txReceiptToMsg, _ ) ) ->
                                    Task.perform txReceiptToMsg (Task.succeed (Err error))

                                ( Nothing, Nothing, Nothing ) ->
                                    Cmd.none
                    in
                    case txHashResult of
                        Ok txHash ->
                            let
                                -- If user cares about the tx being broadcast or mined, talk to the node accordingly, else nothing.
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

                        -- If decoding TxHash fails, send Err to all of the user's callbacks.
                        Err error ->
                            ( TxSentry sentry
                            , Cmd.batch
                                [ txSignedCmd
                                , failOtherCallbacks error
                                ]
                            )

                -- This shouldn't occur. A ref should always be associated with some TxState.
                Nothing ->
                    ( TxSentry sentry
                    , Cmd.none
                    )

        TxSent ref txResult ->
            -- When Tx has been sucessfully broadcast and verifiably sits within the networks Tx Queue,
            -- AND an "onBroadcastTagger" and/or "onMinedTagger" was provided by the user,
            -- Msg User Land accordingly.
            -- let
            --     _ =
            --         debugHelp sentry.debug log.broadcast (toString txResult)
            -- in
            case Dict.get ref sentry.txs of
                Just txState ->
                    case txResult of
                        Ok tx ->
                            let
                                txBroadcastCmd =
                                    case txState.onBroadcastTagger of
                                        Just txToMsg ->
                                            Task.perform txToMsg (Task.succeed <| Ok tx)

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

                        Err error ->
                            let
                                failOtherCallbacks =
                                    case ( txState.onBroadcastTagger, txState.onMinedTagger ) of
                                        ( Just txToMsg, _ ) ->
                                            Task.perform txToMsg (Task.succeed <| Err "Error with TxSent stuff")

                                        -- Task.perform txToMsg (Task.succeed <| Err <| toString error)
                                        ( _, Just ( txReceiptToMsg, _ ) ) ->
                                            Task.perform txReceiptToMsg (Task.succeed <| Err "Error with TxSent stuff")

                                        -- Task.perform txReceiptToMsg (Task.succeed <| Err <| toString error)
                                        ( Nothing, Nothing ) ->
                                            Cmd.none
                            in
                            ( TxSentry sentry
                            , failOtherCallbacks
                            )

                -- This shouldn't occur. A ref should always be associated with some TxState.
                Nothing ->
                    ( TxSentry sentry, Cmd.none )

        TxMined ref txReceiptResult ->
            -- When Tx is mined because a TxReceipt was returned by the network...
            -- let
            --     _ =
            --         debugHelp sentry.debug log.mined (toString txReceiptResult)
            -- in
            case Dict.get ref sentry.txs of
                Just txState ->
                    case txReceiptResult of
                        Ok txReceipt ->
                            let
                                cmdIfMined =
                                    case txState.onMinedTagger of
                                        Just ( txReceiptToMsg, Nothing ) ->
                                            -- ...and user DOESN'T need to track the block depth of the tx,
                                            -- then Send TxReceipt to User Land
                                            Task.perform txReceiptToMsg (Task.succeed <| Ok txReceipt)

                                        Just ( txReceiptToMsg, Just tracker ) ->
                                            let
                                                txTracker =
                                                    { currentDepth = 1
                                                    , minedInBlock = txReceipt.blockNumber
                                                    , stopWatchingAtBlock = txReceipt.blockNumber + (tracker.confirmations - 1)
                                                    , lastCheckedBlock = txReceipt.blockNumber
                                                    , txHash = txReceipt.hash
                                                    , doneWatching = False
                                                    , reOrg = False
                                                    }

                                                -- _ =
                                                --     debugHelp sentry.debug log.trackTx txTracker
                                            in
                                            -- ...or user DOES need to trackthe  block depth of the tx,
                                            -- then Send TxReceipt and/or TxTracker to User Land
                                            Cmd.batch
                                                [ Task.attempt (TrackTx ref txTracker) (Eth.getBlockNumber sentry.nodePath)
                                                    |> Cmd.map sentry.tagger
                                                , Task.perform txReceiptToMsg (Task.succeed <| Ok txReceipt)
                                                , Task.perform tracker.toMsg (Task.succeed txTracker)
                                                ]

                                        -- This should not happen. OnMined tagger will exist if we've gotten to this point.
                                        Nothing ->
                                            Cmd.none
                            in
                            -- Change TxState from pending to Mined, and fire the relevant Cmd (see above).
                            ( TxSentry { sentry | txs = Dict.update ref (txStatusMined txReceipt) sentry.txs }
                            , cmdIfMined
                            )

                        -- If TxReceipt Decoding Fails, alert user.
                        Err error ->
                            let
                                cmdIfMinedFail =
                                    case txState.onMinedTagger of
                                        Just ( txReceiptToMsg, _ ) ->
                                            Task.perform txReceiptToMsg (Task.succeed <| Err "TxReceipt decoding failure")

                                        -- TODO Reimplement this better
                                        --Task.perform txReceiptToMsg (Task.succeed <| Err <| toString error)
                                        Nothing ->
                                            Cmd.none
                            in
                            ( TxSentry sentry
                            , cmdIfMinedFail
                            )

                -- This shouldn't occur. A ref should always be associated with some TxState.
                Nothing ->
                    ( TxSentry sentry, Cmd.none )

        TrackTx ref txTracker (Ok newBlockNum) ->
            let
                newTxTracker =
                    { txTracker
                        | lastCheckedBlock = newBlockNum
                        , currentDepth = (newBlockNum - txTracker.minedInBlock) + 1
                    }
            in
            if newBlockNum == txTracker.stopWatchingAtBlock then
                -- If block depth is reached, send DeepEnough msg
                case getTxTrackerToMsg sentry.txs ref of
                    Just blockDepthToMsg ->
                        -- let
                        --     _ =
                        --         debugHelp sentry.debug log.trackTx { newTxTracker | doneWatching = True }
                        -- in
                        ( TxSentry sentry
                        , Task.perform blockDepthToMsg
                            (Eth.getTxReceipt sentry.nodePath txTracker.txHash
                                |> Task.andThen (\_ -> Task.succeed { newTxTracker | doneWatching = True })
                                |> Task.onError
                                    (\_ ->
                                        Task.succeed <|
                                            { newTxTracker | reOrg = True, doneWatching = True }
                                    )
                            )
                        )

                    Nothing ->
                        ( TxSentry sentry, Cmd.none )

            else if newBlockNum == txTracker.lastCheckedBlock then
                -- Else keep polling for a new block
                ( TxSentry sentry
                , Task.attempt (TrackTx ref txTracker)
                    (Process.sleep 2000
                        |> Task.andThen (\_ -> Eth.getBlockNumber sentry.nodePath)
                    )
                    |> Cmd.map sentry.tagger
                )

            else
                -- If the newly polled blockNumber /= the previously polled blockNumber,
                -- let the user know a new block depth has been reached.
                case getTxTrackerToMsg sentry.txs ref of
                    Just blockDepthToMsg ->
                        -- let
                        --     _ =
                        --         debugHelp sentry.debug log.trackTx newTxTracker
                        -- in
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
            -- let
            --     _ =
            --         debugHelp sentry.debug log.trackTx ("Error getting latest block. Info: " ++ toString error)
            -- in
            ( TxSentry sentry, Cmd.none )

        ErrorDecoding error ->
            -- let
            --     _ =
            --         debugHelp sentry.debug log.decodeError error
            -- in
            ( TxSentry sentry, Cmd.none )



-- Chain Helpers


pollTxReceipt : HttpProvider -> TxHash -> Task Http.Error TxReceipt
pollTxReceipt nodePath txHash =
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
        |> Maybe.map .toMsg



-- Decoders/Encoders


encodeTxData : Int -> Value -> Value
encodeTxData ref txParamVal =
    Encode.object
        [ ( "ref", Encode.int ref )
        , ( "txParams", txParamVal )
        ]


{-| decodeTxData
-}
decodeTxData : Value -> Msg
decodeTxData val =
    case Decode.decodeValue txIdResponseDecoder val of
        Ok result ->
            case result.txHash of
                Just txHash ->
                    TxSigned result.ref
                        (Ok txHash)

                Nothing ->
                    TxSigned result.ref
                        (Err <| "Problem signing/broadcasting Tx. Ref #" ++ String.fromInt result.ref)

        Err error ->
            -- TODO actually unpack `error` after I become not lazy and in a rush
            ErrorDecoding "Error decoding tx data"


txIdResponseDecoder : Decoder { ref : Int, txHash : Maybe TxHash }
txIdResponseDecoder =
    Decode.map2 (\ref txHash -> { ref = ref, txHash = txHash })
        (Decode.field "ref" Decode.int)
        (Decode.field "txHash" (Decode.maybe Decode.txHash))


newTxState : Send -> CustomSend msg -> TxState msg
newTxState txParams { onSign, onBroadcast, onMined } =
    { params = txParams
    , onSignedTagger = onSign
    , onBroadcastTagger = onBroadcast
    , onMinedTagger = onMined
    , status = Signing txParams
    }



-- Logger


debugHelp debug logText val =
    case debug of
        Just debugFunc ->
            debugFunc ("TxSentry - " ++ logText) val

        Nothing ->
            val


log =
    { signed = "Tx Signed"
    , broadcast = "Tx Broadcasted Succesfully to Network"
    , broadcastError = "Error Broadcasting"
    , mined = "Tx Mined"
    , minedError = "Error Mining"
    , nodeChanged = "Nodepath changed"
    , trackTx = "TxTracker"
    , decodeError = "Error decoding"
    }
