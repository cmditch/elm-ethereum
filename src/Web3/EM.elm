effect module Web3.EM
    where { command = MyCmd, subscription = MySub }
    exposing
        ( eventSentry
        , watchEvent
        , stopWatchingEvent
        , watchFilter
        , stopWatchingFilter
        , reset
        )

import Dict
import Task exposing (Task)
import Json.Encode as Encode
import Web3.Internal exposing (EventRequest, contractFuncHelper)


-- SUBSCRIPTIONS


type MySub msg
    = EventSentry String (String -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap method (EventSentry name toMsg) =
    EventSentry name (toMsg >> method)


eventSentry : String -> (String -> msg) -> Sub msg
eventSentry eventId toMsg =
    subscription (EventSentry eventId toMsg)



-- COMMANDS


type MyCmd msg
    = WatchEvent String EventRequest
    | StopWatchingEvent String
    | WatchFilter String String
    | StopWatchingFilter String
    | Reset


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ cmd =
    case cmd of
        WatchEvent name request ->
            WatchEvent name request

        StopWatchingEvent name ->
            StopWatchingEvent name

        WatchFilter name arg ->
            WatchFilter name arg

        StopWatchingFilter name ->
            StopWatchingFilter name

        Reset ->
            Reset


watchEvent : String -> EventRequest -> Cmd msg
watchEvent name request =
    command <| WatchEvent name request


stopWatchingEvent : String -> Cmd msg
stopWatchingEvent name =
    command <| StopWatchingEvent name


watchFilter : String -> String -> Cmd msg
watchFilter name arg =
    command <| WatchFilter name arg


stopWatchingFilter : String -> Cmd msg
stopWatchingFilter name =
    command <| StopWatchingFilter name


reset : Cmd msg
reset =
    command <| Reset



-- MANAGER


type Web3Event
    = Web3Event


type alias State msg =
    { subs : SubsDict msg
    , web3Events : Web3EventDict
    }


type alias SubsDict msg =
    Dict.Dict String (List (String -> msg))


type alias Web3EventDict =
    Dict.Dict String Web3Event


init : Task Never (State msg)
init =
    Task.succeed (State Dict.empty Dict.empty)



-- HANDLE APP MESSAGES


(&>) : Task a x -> Task a b -> Task a b
(&>) t1 t2 =
    t1 |> Task.andThen (\_ -> t2)


onEffects : Platform.Router msg Msg -> List (MyCmd msg) -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router cmds subs state =
    let
        sendMessages =
            sendMessagesHelp router cmds state.web3Events

        newSubs =
            buildSubsDict subs Dict.empty
    in
        sendMessages
            |> Task.andThen (\web3EventDict -> State newSubs web3EventDict |> Task.succeed)


sendMessagesHelp : Platform.Router msg Msg -> List (MyCmd msg) -> Web3EventDict -> Task Never Web3EventDict
sendMessagesHelp router cmds eventDict =
    case cmds of
        [] ->
            Task.succeed eventDict

        (WatchEvent name request) :: rest ->
            case Dict.get name eventDict of
                Just _ ->
                    sendMessagesHelp router rest eventDict

                Nothing ->
                    initWatch router name request
                        |> Task.andThen (\web3Event -> Task.succeed <| Dict.insert name web3Event eventDict)
                        |> Task.andThen (\newEventDict -> sendMessagesHelp router rest newEventDict)

        (StopWatchingEvent name) :: rest ->
            case Dict.get name eventDict of
                Just web3Event ->
                    initStopWatching web3Event
                        &> Task.succeed (Dict.remove name eventDict)
                        |> Task.andThen (\newEventDict -> sendMessagesHelp router rest newEventDict)

                Nothing ->
                    sendMessagesHelp router rest eventDict

        (WatchFilter name arg) :: rest ->
            case Dict.get name eventDict of
                Just _ ->
                    sendMessagesHelp router rest eventDict

                Nothing ->
                    initFilter router name arg
                        |> Task.andThen (\web3Event -> Task.succeed <| Dict.insert name web3Event eventDict)
                        |> Task.andThen (\newEventDict -> sendMessagesHelp router rest newEventDict)

        (StopWatchingFilter name) :: rest ->
            case Dict.get name eventDict of
                Just web3Event ->
                    initStopWatching web3Event
                        &> Task.succeed (Dict.remove name eventDict)
                        |> Task.andThen (\newEventDict -> sendMessagesHelp router rest newEventDict)

                Nothing ->
                    sendMessagesHelp router rest eventDict

        -- TODO Performing reset manually on only events in the Web3Event dict, without using web3.reset().
        --      Need to evaluate this in light of what reset actually does.
        Reset :: rest ->
            Dict.values eventDict
                |> List.map initStopWatching
                |> List.foldl (&>) (Task.succeed ())
                |> Task.andThen (\_ -> sendMessagesHelp router rest Dict.empty)


initWatch : Platform.Router msg Msg -> String -> EventRequest -> Task Never Web3Event
initWatch router name { abi, address, argsFilter, filterParams, eventName } =
    let
        method =
            contractFuncHelper abi address eventName

        params =
            Encode.list [ argsFilter, filterParams ]
    in
        Native.Web3.watchEvent
            { method = method, params = params, isContractEvent = Encode.bool True }
            -- This is the callback which talks to Event.onSelfMsg, in Web3.js it's within watch() as onMessage(stringifiedWeb3Log)
            (\log -> Platform.sendToSelf router (RecieveLog name log))


initFilter : Platform.Router msg Msg -> String -> String -> Task Never Web3Event
initFilter router name arg =
    let
        method =
            "eth.filter('" ++ arg ++ "')"
    in
        Native.Web3.watchEvent
            { method = method, isContractEvent = Encode.bool False }
            -- This is the callback which talks to Event.onSelfMsg, in Web3.js it's within watch() as onMessage(stringifiedWeb3Log)
            (\log -> Platform.sendToSelf router (RecieveLog name log))


initStopWatching : Web3Event -> Task Never ()
initStopWatching web3Event =
    Native.Web3.stopWatchingEvent web3Event


buildSubsDict : List (MySub msg) -> SubsDict msg -> SubsDict msg
buildSubsDict subs dict =
    case subs of
        [] ->
            dict

        (EventSentry name toMsg) :: rest ->
            buildSubsDict rest (Dict.update name (add toMsg) dict)


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
onSelfMsg router (RecieveLog name log) state =
    let
        sends =
            Dict.get name state.subs
                |> Maybe.withDefault []
                |> List.map (\tagger -> Platform.sendToApp router (tagger log))
    in
        Task.sequence sends &> Task.succeed state
