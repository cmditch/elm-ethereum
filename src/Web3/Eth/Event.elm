effect module Web3.Eth.Event
    where { command = MyCmd, subscription = MySub }
    exposing
        ( sentry
        , watch
        , stopWatching
        )

import Dict
import Task exposing (Task)
import Web3.Eth.Types exposing (..)
import Web3.Internal exposing (EventRequest)


-- SUBSCRIPTIONS


type MySub msg
    = Sentry String (String -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap func (Sentry name toMsg) =
    Sentry name (toMsg >> func)


sentry : String -> (String -> msg) -> Sub msg
sentry eventId toMsg =
    subscription (Sentry eventId toMsg)



-- COMMANDS


type MyCmd msg
    = Watch String EventRequest
    | StopWatching String


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ cmd =
    case cmd of
        Watch name request ->
            Watch name request

        StopWatching name ->
            StopWatching name


watch : String -> EventRequest -> Cmd msg
watch name request =
    command <| Watch name request


stopWatching : String -> Cmd msg
stopWatching name =
    command <| StopWatching name



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
            |> Task.andThen (\web3EventDict -> Task.succeed <| State newSubs web3EventDict)


sendMessagesHelp : Platform.Router msg Msg -> List (MyCmd msg) -> Web3EventDict -> Task Never Web3EventDict
sendMessagesHelp router cmds eventDict =
    case cmds of
        [] ->
            Task.succeed eventDict

        (Watch name request) :: rest ->
            case Dict.get name eventDict of
                Just _ ->
                    sendMessagesHelp router rest eventDict

                Nothing ->
                    initWatch router name request
                        |> Task.andThen (\web3Event -> Task.succeed <| Dict.insert name web3Event eventDict)
                        |> Task.andThen (\newEventDict -> sendMessagesHelp router rest newEventDict)

        (StopWatching name) :: rest ->
            case Dict.get name eventDict of
                Just web3Event ->
                    initStopWatching web3Event
                        &> Task.succeed (Dict.remove name eventDict)
                        |> Task.andThen (\newEventDict -> sendMessagesHelp router rest newEventDict)

                Nothing ->
                    sendMessagesHelp router rest eventDict


initWatch : Platform.Router msg Msg -> String -> EventRequest -> Task Never Web3Event
initWatch router name request =
    let
        -- TODO Build up the function string in here?
        (Abi abi_) =
            request.abi

        (Address address_) =
            request.address
    in
        Native.Web3.watch
            { request | address = address_, abi = abi_ }
            -- This is the callback which talks to Event.onSelfMsg, in Web3.js it's within watch() as onMessage(stringifiedWeb3Log)
            (\log -> Platform.sendToSelf router (RecieveLog name log))


initStopWatching : Web3Event -> Task Never ()
initStopWatching web3Event =
    Native.Web3.stopWatching web3Event


buildSubsDict : List (MySub msg) -> SubsDict msg -> SubsDict msg
buildSubsDict subs dict =
    case subs of
        [] ->
            dict

        (Sentry name toMsg) :: rest ->
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
