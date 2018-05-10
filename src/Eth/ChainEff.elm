module Eth.ChainEff
    exposing
        ( ChainEff
        , Sentry
        , execute
        , batch
        , none
        , map
        , sendTx
        , sendWithReceipt
        , customSend
        , watchEvent
        , watchEventOnce
        , unWatch
        )

{-| For dApp Single Page Applications
If your EventSentry or TxSentry live at the top level of your model, and you are sending txs or listening to event in your sub-pages,
use ChainEff. See examples.


# Core

@docs ChainEff, Sentry, execute, batch, none, map


# TxSentry

@docs sendTx, sendWithReceipt, customSend


# EventSentry

@docs watchEvent, watchEventOnce, unWatch

-}

import Json.Decode exposing (Value)
import Eth.Sentry.Event as EventSentry
import Eth.Sentry.Tx as TxSentry
import Eth.Types exposing (..)


{-| -}
type ChainEff msg
    = SendTx (Tx -> msg) Send
    | SendWithReceipt (Tx -> msg) (TxReceipt -> msg) Send
    | CustomSend (TxSentry.CustomSend msg) Send
    | WatchEvent (Value -> msg) LogFilter
    | WatchEventOnce (Value -> msg) LogFilter
    | UnWatch LogFilter
    | Many (List (ChainEff msg))
    | None


{-| -}
type alias Sentry msg =
    ( TxSentry.TxSentry msg, EventSentry.EventSentry msg )


{-| -}
execute : Sentry msg -> ChainEff msg -> ( Sentry msg, Cmd msg )
execute sentry chainEff =
    executeHelp [] sentry [ chainEff ]


{-| -}
batch : List (ChainEff msg) -> ChainEff msg
batch =
    Many


{-| -}
none : ChainEff msg
none =
    None


{-| -}
map : (subMsg -> msg) -> ChainEff subMsg -> ChainEff msg
map f subEff =
    case subEff of
        SendTx subMsg send ->
            SendTx (subMsg >> f) send

        SendWithReceipt subMsg1 subMsg2 send ->
            SendWithReceipt (subMsg1 >> f) (subMsg2 >> f) send

        CustomSend { onSign, onBroadcast, onMined } send ->
            let
                newCustomSend =
                    TxSentry.CustomSend
                        (Maybe.map ((<<) f) onSign)
                        (Maybe.map ((<<) f) onBroadcast)
                        (Maybe.map
                            (\( subMsg1, blockDepthInfo ) ->
                                ( subMsg1 >> f
                                , Maybe.map
                                    (\( depth, subMsg2 ) -> ( depth, subMsg2 >> f ))
                                    blockDepthInfo
                                )
                            )
                            onMined
                        )
            in
                CustomSend newCustomSend send

        WatchEvent subMsg logFilter ->
            WatchEvent (subMsg >> f) logFilter

        WatchEventOnce subMsg logFilter ->
            WatchEventOnce (subMsg >> f) logFilter

        UnWatch logFilter ->
            UnWatch logFilter

        Many effs ->
            Many <| List.map (map f) effs

        None ->
            None


{-| -}
sendTx : (Tx -> msg) -> Send -> ChainEff msg
sendTx =
    SendTx


{-| -}
sendWithReceipt : (Tx -> msg) -> (TxReceipt -> msg) -> Send -> ChainEff msg
sendWithReceipt =
    SendWithReceipt


{-| -}
customSend : TxSentry.CustomSend msg -> Send -> ChainEff msg
customSend =
    CustomSend


{-| -}
watchEvent : (Value -> msg) -> LogFilter -> ChainEff msg
watchEvent =
    WatchEvent


{-| -}
watchEventOnce : (Value -> msg) -> LogFilter -> ChainEff msg
watchEventOnce =
    WatchEventOnce


{-| -}
unWatch : LogFilter -> ChainEff msg
unWatch =
    UnWatch



-- External
{- TODO
   Make impossible states impossible
   e.g, running SendTx if you have only supplied EventEff Sentry
-}


executeHelp : List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
executeHelp cmds sentry chainEffs =
    case chainEffs of
        [] ->
            ( sentry, Cmd.batch cmds )

        (SendTx toMsg txParams) :: xs ->
            sendTxHelp toMsg txParams cmds sentry xs

        (SendWithReceipt toMsg1 toMsg2 txParams) :: xs ->
            sendWithReceiptHelp toMsg1 toMsg2 txParams cmds sentry xs

        (CustomSend customSend txParams) :: xs ->
            customSendHelp customSend txParams cmds sentry xs

        (WatchEvent toMsg logFilter) :: xs ->
            watchEventHelp toMsg logFilter cmds sentry xs

        (WatchEventOnce toMsg logFilter) :: xs ->
            watchEventOnceHelp toMsg logFilter cmds sentry xs

        (UnWatch logFilter) :: xs ->
            unWatchHelp logFilter cmds sentry xs

        (Many chainEffs_) :: xs ->
            executeHelp cmds sentry (chainEffs_ ++ xs)

        None :: xs ->
            executeHelp cmds sentry xs



-- TxSentry Helpers


sendTxHelp : (Tx -> msg) -> Send -> List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
sendTxHelp toMsg txParams cmds ( txSentry, eventSentry ) xs =
    let
        ( newTxSentry, txCmd ) =
            TxSentry.send toMsg txSentry txParams
    in
        executeHelp (txCmd :: cmds) ( newTxSentry, eventSentry ) xs


sendWithReceiptHelp : (Tx -> msg) -> (TxReceipt -> msg) -> Send -> List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
sendWithReceiptHelp toMsg1 toMsg2 txParams cmds ( txSentry, eventSentry ) xs =
    let
        ( newTxSentry, txCmd ) =
            TxSentry.sendWithReceipt toMsg1 toMsg2 txSentry txParams
    in
        executeHelp (txCmd :: cmds) ( newTxSentry, eventSentry ) xs


customSendHelp : TxSentry.CustomSend msg -> Send -> List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
customSendHelp customSend txParams cmds ( txSentry, eventSentry ) xs =
    let
        ( newTxSentry, txCmd ) =
            TxSentry.customSend txSentry customSend txParams
    in
        executeHelp (txCmd :: cmds) ( newTxSentry, eventSentry ) xs



-- EventSentry Helpers


watchEventHelp : (Value -> msg) -> LogFilter -> List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
watchEventHelp toMsg logFilter cmds ( txSentry, eventSentry ) xs =
    let
        ( newEventSentry, eventCmd ) =
            EventSentry.watch toMsg eventSentry logFilter
    in
        executeHelp (eventCmd :: cmds) ( txSentry, newEventSentry ) xs


watchEventOnceHelp : (Value -> msg) -> LogFilter -> List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
watchEventOnceHelp toMsg logFilter cmds ( txSentry, eventSentry ) xs =
    let
        ( newEventSentry, eventCmd ) =
            EventSentry.watchOnce toMsg eventSentry logFilter
    in
        executeHelp (eventCmd :: cmds) ( txSentry, newEventSentry ) xs


unWatchHelp : LogFilter -> List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
unWatchHelp logFilter cmds ( txSentry, eventSentry ) xs =
    let
        ( newEventSentry, eventCmd ) =
            EventSentry.unWatch eventSentry logFilter
    in
        executeHelp (eventCmd :: cmds) ( txSentry, newEventSentry ) xs
