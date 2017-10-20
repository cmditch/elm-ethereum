effect module Web3.Eth.Subscribe where { command = MyCmd, subscription = MySub } exposing (..)

import Web3.Types exposing (..)
import Web3.Decoders exposing (decodeWeb3String, txObjDecoder, blockHeaderDecoder, syncStatusDecoder)
import Task exposing (Task)
import Dict exposing (Dict)
import Process


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


start : Subscription -> Cmd msg
start subType =
    command <| Subscribe subType


stop : Subscription -> Cmd msg
stop subType =
    command <| Unsubscribe subType


clearSubscriptions : Cmd msg
clearSubscriptions =
    command ClearSubscriptions



-- MANAGER SUBSCRIPTIONS


type MySub msg
    = EventSentry Subscription (String -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap tagger (EventSentry subType toMsg) =
    EventSentry subType (toMsg >> tagger)


pendingTxs : (Result Error TxObj -> msg) -> Sub msg
pendingTxs toMsg =
    subscription <| EventSentry PendingTxs (decodeWeb3String txObjDecoder >> toMsg)


newBlockHeaders : (Result Error BlockHeader -> msg) -> Sub msg
newBlockHeaders toMsg =
    subscription <| EventSentry NewBlockHeaders (decodeWeb3String blockHeaderDecoder >> toMsg)


syncing : (Result Error (Maybe SyncStatus) -> msg) -> Sub msg
syncing toMsg =
    subscription <| EventSentry Syncing (decodeWeb3String syncStatusDecoder >> toMsg)


logs : (String -> msg) -> EventId -> Sub msg
logs toMsg eventId =
    let
        unUsedParams =
            { fromBlock = Latest
            , toBlock = Latest
            , address = []
            , topics = []
            }
    in
        subscription <| EventSentry (Logs unUsedParams eventId) toMsg


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
            sendMessagesHelp router state.eventEmitters cmds

        newSubs =
            buildSubsDict subs Dict.empty
    in
        sendMessages
            |> Task.andThen (\newEventEmitters -> State newSubs newEventEmitters |> Task.succeed)


sendMessagesHelp : Platform.Router msg Msg -> EventEmitterDict -> List (MyCmd msg) -> Task Never EventEmitterDict
sendMessagesHelp router eventEmittersDict cmds =
    let
        subHelp =
            subscribeHelp router eventEmittersDict cmds

        unsubHelp =
            unsubscribeHelp router eventEmittersDict cmds
    in
        case cmds of
            [] ->
                Task.succeed eventEmittersDict

            (Subscribe subType) :: rest ->
                subHelp subType

            (Unsubscribe subType) :: rest ->
                unsubHelp subType

            ClearSubscriptions :: rest ->
                clearSubs &> Task.succeed Dict.empty



-- TODO clear subscriptions myself or use the web3 function?
-- if I do it myself, it will not clear contract subscriptions
-- unless I bring the merge the contract effect manager in here


subscribeHelp : Platform.Router msg Msg -> EventEmitterDict -> List (MyCmd msg) -> Subscription -> Task Never EventEmitterDict
subscribeHelp router eventEmittersDict cmds subType =
    case subType of
        _ ->
            case Dict.get (subToEventId subType) eventEmittersDict of
                Just _ ->
                    sendMessagesHelp router eventEmittersDict cmds

                Nothing ->
                    createEventEmitter subType
                        |> Task.andThen
                            (\eventEmitter ->
                                (Process.spawn (eventSubscribe router eventEmitter (subToEventId subType)))
                                    &> Task.succeed (Dict.insert (subToEventId subType) eventEmitter eventEmittersDict)
                            )
                        |> Task.andThen (\newEventEmitters -> sendMessagesHelp router newEventEmitters cmds)


unsubscribeHelp : Platform.Router msg Msg -> EventEmitterDict -> List (MyCmd msg) -> Subscription -> Task Never EventEmitterDict
unsubscribeHelp router eventEmittersDict cmds subType =
    case subType of
        _ ->
            case Dict.get (subToEventId subType) eventEmittersDict of
                Just eventEmitter ->
                    eventUnsubscribe eventEmitter
                        &> Task.succeed (Dict.remove (subToEventId subType) eventEmittersDict)
                        |> Task.andThen (\newEventEmitters -> sendMessagesHelp router newEventEmitters cmds)

                Nothing ->
                    sendMessagesHelp router eventEmittersDict cmds


subToEventId : Subscription -> EventId
subToEventId subType =
    case subType of
        PendingTxs ->
            "pendingTransactions"

        NewBlockHeaders ->
            "newBlockHeaders"

        Syncing ->
            "syncing"

        Logs _ eventId ->
            eventId


createEventEmitter : Subscription -> Task Never EventEmitter
createEventEmitter subType =
    case subType of
        Logs logParams _ ->
            Native.Subscribe.createEventEmitter "logs" {}

        _ ->
            Native.Subscribe.createEventEmitter (subToEventId subType)


eventSubscribe : Platform.Router msg Msg -> EventEmitter -> String -> Task Never ()
eventSubscribe router eventEmitter eventId =
    Native.Subscribe.eventSubscribe
        eventEmitter
        (\log -> Platform.sendToSelf router (RecieveLog eventId log))


eventUnsubscribe : EventEmitter -> Task Never ()
eventUnsubscribe eventEmitter =
    Native.Subscribe.eventUnsubscribe eventEmitter


clearSubs : Task Never ()
clearSubs =
    Native.Subscribe.clearSubscriptions


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
