effect module Web3.Eth.Event where { command = MyCmd, subscription = MySub } exposing (MyCmd)

import Dict
import Process
import Task exposing (Task)
import Time exposing (Time)
import Web3.Types exposing (Expect(..))
import Web3.Eth.Types exposing (..)
import Web3.Internal exposing (EventRequest)
import Web3.LowLevel exposing (eventWatch)
import Json.Encode as Encode exposing (Value)


-- SUBSCRIPTIONS


type MySub msg
    = Sentry String (String -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap func (Sentry name toMsg) =
    Sentry name (toMsg >> func)



-- COMMANDS


type MyCmd msg
    = Watch String EventRequest



-- | StopWatching String


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ cmd =
    case cmd of
        Watch name request ->
            Watch name request



-- StopWatching name ->
--     StopWatching name
-- MANAGER


type Web3Event
    = Web3Event


type alias State msg =
    { subs : Dict.Dict String (List (String -> msg))
    , web3Events : Dict.Dict String Web3Event
    }


init : Task Never (State msg)
init =
    Task.succeed (State Dict.empty Dict.empty)



-- HANDLE APP MESSAGES


(&>) t1 t2 =
    Task.andThen (\_ -> t2) t1


onEffects : Platform.Router msg Msg -> List (MyCmd msg) -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router cmds subs state =
    case cmds of
        [] ->
            Task.succeed state

        (Watch name request) :: rest ->
            initWatch name request router
                |> Task.andThen (\web3Event -> Task.succeed (Dict.insert name web3Event state.web3Events))
                |> Task.andThen (\web3Events -> Task.succeed { state | web3Events = web3Events })


type Msg
    = RecieveLog String String


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router (RecieveLog filterId log) state =
    let
        sends =
            Dict.get filterId state.subs
                |> Maybe.withDefault []
                |> List.map (\tagger -> Platform.sendToApp router (tagger log))
    in
        Task.sequence sends &> Task.succeed state


sentry : String -> (String -> msg) -> Sub msg
sentry eventId toMsg =
    subscription (Sentry eventId toMsg)


initWatch : String -> EventRequest -> Platform.Router msg Msg -> Task Never Web3Event
initWatch name request router =
    let
        (Abi abi_) =
            request.abi

        (Address address_) =
            request.address
    in
        Native.Web3.watch { request | address = address_, abi = abi_ } (\msg -> Platform.sendToSelf router (RecieveLog name msg))


watch : String -> EventRequest -> Cmd msg
watch name request =
    command <| Watch name request
