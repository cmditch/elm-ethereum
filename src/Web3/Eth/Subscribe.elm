effect module Web3.Eth.Subscribe where { command = MyCmd, subscription = MySub } exposing (..)

import Web3.Types exposing (..)
import Task exposing (Task)
import Dict exposing (Dict)
import Process


-- Effect Manager
-- type Subscription
--     = PendingTxs
--     | NewBlockHeaders
--     | Syncing
--     | Logs LogParams
--
-- MANAGER COMMANDS


type MyCmd msg
    = Subscribe Subscription
    | Unsubscribe Subscription
    | ClearSubscriptions


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ cmd =
    case cmd of
        Subscribe subType ->
            Subscribe subType

        Unsubscribe eventId ->
            Unsubscribe eventId

        ClearSubscriptions ->
            ClearSubscriptions


pendingTransactions : Cmd msg
pendingTransactions =
    command <| Subscribe PendingTxs


newBlockHeaders : Cmd msg
newBlockHeaders =
    command <| Subscribe NewBlockHeaders


syncing : Cmd msg
syncing =
    command <| Subscribe Syncing


logs : LogParams -> Cmd msg
logs params =
    command <| Subscribe (Logs params)


clearSubscriptions : Cmd msg
clearSubscriptions =
    command ClearSubscriptions



-- MANAGER SUBSCRIPTIONS


type MySub msg
    = EventSentry Subscription (String -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap tagger (EventSentry subType toMsg) =
    EventSentry subType (toMsg >> tagger)


eventSentry : Subscription -> (String -> msg) -> Sub msg
eventSentry subType toMsg =
    subscription <| EventSentry subType toMsg



-- MANAGER


type EventEmitter
    = EventEmitter


type alias State msg =
    { subs : SubsDict msg
    , eventEmitters : EventEmitterDict
    }


type alias SubsDict msg =
    Dict.Dict String (List (String -> msg))


type alias EventEmitterDict =
    Dict.Dict String EventEmitter


init : Task Never (State msg)
init =
    Task.succeed (State Dict.empty Dict.empty)


(&>) : Task a x -> Task a b -> Task a b
(&>) t1 t2 =
    t1 |> Task.andThen (\_ -> t2)


onEffects : Platform.Router msg Msg -> List (MyCmd msg) -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router cmds subs state =
    let
        sendMessages =
            sendMessagesHelp router cmds state.eventEmitters

        newSubs =
            buildSubsDict subs Dict.empty
    in
        sendMessages
            |> Task.andThen (\newEventEmitters -> State newSubs newEventEmitters |> Task.succeed)


sendMessagesHelp : Platform.Router msg Msg -> List (MyCmd msg) -> EventEmitterDict -> Task Never EventEmitterDict
sendMessagesHelp router cmds eventEmittersDict =
    case cmds of
        _ ->
            Task.succeed eventEmittersDict



-- (Subscribe abi eventName address eventId) :: rest ->
--     case Dict.get eventId eventEmittersDict of
--         Just _ ->
--             sendMessagesHelp router rest eventEmittersDict
--
--         Nothing ->
--             createEventEmitter abi address eventName
--                 |> Task.andThen
--                     (\eventEmitter ->
--                         (Process.spawn (eventSubscribe router eventEmitter eventId))
--                             &> Task.succeed (Dict.insert eventId eventEmitter eventEmittersDict)
--                     )
--                 |> Task.andThen (\newEventEmitters -> sendMessagesHelp router rest newEventEmitters)
--
-- (Unsubscribe eventId) :: rest ->
--     case Dict.get eventId eventEmittersDict of
--         Just eventEmitter ->
--             Process.spawn (eventUnsubscribe eventEmitter)
--                 &> Task.succeed (Dict.remove eventId eventEmittersDict)
--
--         Nothing ->
--             sendMessagesHelp router rest eventEmittersDict
{-

   web3.eth.subscribe("pendingTransactions")
   web3.eth.subscribe("newBlockHeaders")
   web3.eth.subscribe("syncing")
   web3.eth.subscribe("logs", options)

-}


createEventEmitter : String -> String -> String -> Task Never EventEmitter
createEventEmitter abi address eventName =
    Native.Web3.createEventEmitter abi address eventName


eventSubscribe : Platform.Router msg Msg -> EventEmitter -> String -> Task Never ()
eventSubscribe router eventEmitter eventId =
    Native.Web3.eventSubscribe
        eventEmitter
        (\log -> Platform.sendToSelf router (RecieveLog eventId log))


eventUnsubscribe : EventEmitter -> Task Never ()
eventUnsubscribe eventEmitter =
    Native.Web3.eventUnsubscribe eventEmitter


buildSubsDict : List (MySub msg) -> SubsDict msg -> SubsDict msg
buildSubsDict subs dict =
    case subs of
        _ ->
            dict



-- (EventSentry eventId toMsg) :: rest ->
--     buildSubsDict rest (Dict.update eventId (add toMsg) dict)


add : a -> Maybe (List a) -> Maybe (List a)
add value maybeList =
    case maybeList of
        Nothing ->
            Just [ value ]

        Just list ->
            Just (value :: list)


type Msg
    = RecieveLog String String


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router (RecieveLog eventId log) state =
    let
        sends =
            Dict.get eventId state.subs
                |> Maybe.withDefault []
                |> List.map (\tagger -> Platform.sendToApp router (tagger log))
    in
        Process.spawn (Task.sequence sends) &> Task.succeed state



--- Working out the API
-- InitEventSubscribe ->
--     model
--         ! [ TC.subscribeAdd ( config.contract, "eventWatchTest" ) ]
--
-- InitEventUnsubscribe ->
--     model
--         ! [ Contract.unsubscribe ( config.contract, "eventWatchTest" ) ]
--
-- InitPendingTxSubscribe ->
--     model
--         ! [ Subscribe.start PendingTxs  ]
--
-- InitPendingTxUnsubscribe ->
--     model
--         ! [ Subscribe.stop PendingTxs ]
--
-- InitCustomSubscribe ->
--     model
--         ! [ Subscribe.start (Logs logParams "id1") ]
--
-- InitCustomUnsubscribe ->
--     model
--         ! [ Subscribe.stop (Logs logParams "id1") ]
--
--
-- subscriptions : Model -> Sub Msg
-- subscriptions model =
--     Sub.batch
--         [ Subscribe.pendingTxs ReceiveMeLatestTxs
--         , Subscribe.blockHeaders ReceiveMeBlocks
--         , Subscribe.logs
--         ]
