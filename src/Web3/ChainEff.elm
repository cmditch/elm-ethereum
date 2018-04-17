module Web3.ChainEff
    exposing
        ( ChainEff
        , Sentry
        , batch
        , sendTx
        , watchEvent
          -- , unWatch
        , watchEventOnce
        , execute
        , none
        , map
        )

import Json.Decode exposing (Value)
import Web3.Eth.EventSentry as EventSentry
import Web3.Eth.TxSentry as TxSentry
import Web3.Eth.Types exposing (..)


-- ChainsEffs


type ChainEff msg
    = SendTx Send (Tx -> msg)
    | WatchEvent LogFilter (Value -> msg)
    | WatchEventOnce LogFilter (Value -> msg)
    | Many (List (ChainEff msg))
    | None


sendTx : Send -> (Tx -> msg) -> ChainEff msg
sendTx =
    SendTx


watchEvent : LogFilter -> (Value -> msg) -> ChainEff msg
watchEvent =
    WatchEvent


watchEventOnce : LogFilter -> (Value -> msg) -> ChainEff msg
watchEventOnce =
    WatchEventOnce



-- implement unWatch


batch : List (ChainEff msg) -> ChainEff msg
batch =
    Many


none : ChainEff msg
none =
    None


map : (subMsg -> msg) -> ChainEff subMsg -> ChainEff msg
map f subEff =
    case subEff of
        SendTx send subMsg ->
            SendTx send (subMsg >> f)

        WatchEvent logFilter subMsg ->
            WatchEvent logFilter (subMsg >> f)

        WatchEventOnce logFilter subMsg ->
            WatchEventOnce logFilter (subMsg >> f)

        Many effs ->
            Many <| List.map (map f) effs

        None ->
            None



-- Sentry


type alias Sentry msg =
    ( TxSentry.TxSentry msg, EventSentry.EventSentry msg )


execute : Sentry msg -> ChainEff msg -> ( Sentry msg, Cmd msg )
execute sentry chainEff =
    executeHelp [] sentry [ chainEff ]


{-| TODO
Make impossible states impossible
e.g, running SendTx if you have only supplied EventEff Sentry
-}
executeHelp : List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
executeHelp cmds sentry chainEffs =
    case chainEffs of
        [] ->
            ( sentry, Cmd.batch cmds )

        (SendTx txParams toMsg) :: xs ->
            sendTxHelp txParams toMsg cmds sentry xs

        (WatchEvent logFilter toMsg) :: xs ->
            watchEventHelp logFilter toMsg cmds sentry xs

        (WatchEventOnce logFilter toMsg) :: xs ->
            watchEventOnceHelp logFilter toMsg cmds sentry xs

        (Many chainEffs_) :: xs ->
            executeHelp cmds sentry (chainEffs_ ++ xs)

        None :: xs ->
            executeHelp cmds sentry xs


sendTxHelp : Send -> (Tx -> msg) -> List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
sendTxHelp txParams toMsg cmds ( txSentry, eventSentry ) xs =
    let
        ( newTxSentry, txCmd ) =
            TxSentry.send txParams toMsg txSentry
    in
        executeHelp (txCmd :: cmds) ( newTxSentry, eventSentry ) xs


watchEventHelp : LogFilter -> (Value -> msg) -> List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
watchEventHelp logFilter toMsg cmds ( txSentry, eventSentry ) xs =
    let
        ( newEventSentry, eventCmd ) =
            EventSentry.watch logFilter toMsg eventSentry
    in
        executeHelp (eventCmd :: cmds) ( txSentry, newEventSentry ) xs


watchEventOnceHelp : LogFilter -> (Value -> msg) -> List (Cmd msg) -> Sentry msg -> List (ChainEff msg) -> ( Sentry msg, Cmd msg )
watchEventOnceHelp logFilter toMsg cmds ( txSentry, eventSentry ) xs =
    let
        ( newEventSentry, eventCmd ) =
            EventSentry.watchOnce logFilter toMsg eventSentry
    in
        executeHelp (eventCmd :: cmds) ( txSentry, newEventSentry ) xs
