effect module Web3.Eth.Event where { command = MyCmd, subscription = MySub } exposing (..)

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
    let
        cmdsTask =
            cmdsHelper router state cmds

        subsTask =
            subsHelper state subs
    in
        cmdsTask &> subsTask


subsHelper state subs =
    let
        a =
            Debug.log "subs: " (toString subs)
    in
        case subs of
            [] ->
                Task.succeed state

            (Sentry name toMsg) :: rest ->
                Task.succeed (Dict.get name state.subs |> Maybe.withDefault [])
                    |> Task.andThen (\subsList -> Task.succeed <| Dict.insert name (toMsg :: subsList) state.subs)
                    |> Task.andThen
                        (\subs_ ->
                            Task.succeed (Dict.get name subs_ |> Maybe.withDefault [])
                                |> Task.andThen (\subsAtKey -> Task.succeed (Debug.log ("subsAtKey " ++ name ++ ": ") (toString subsAtKey)))
                                |> Task.andThen (\_ -> Task.succeed { state | subs = subs_ })
                        )


cmdsHelper router state cmds =
    case cmds of
        [] ->
            Task.succeed state

        (Watch name request) :: rest ->
            let
                a =
                    Dict.get name state.subs
                        |> Maybe.withDefault []
                        |> Debug.log "onSelfMsg State: "
                        << toString

                b =
                    Debug.log "Event name: " name
            in
                initWatch name request router
                    |> Task.andThen (\web3Event -> Task.succeed (Dict.insert name web3Event state.web3Events))
                    |> Task.andThen (\web3Events -> Task.succeed { state | web3Events = web3Events })


type Msg
    = RecieveLog String String


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router (RecieveLog name log) state =
    let
        b =
            Debug.log "State" (name ++ " -- " ++ log)

        c =
            Dict.get name state.subs
                |> Maybe.withDefault []
                |> Debug.log "tagged with: "
                << toString

        sends =
            Dict.get name state.subs
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
        Native.Web3.watch
            { request | address = address_, abi = abi_ }
            -- This is the callback which talks to Event.onSelfMsg, in Web3.js it's within watch() as onMessage(stringifiedWeb3Log)
            (\log -> Platform.sendToSelf router (RecieveLog name log))


watch : String -> EventRequest -> Cmd msg
watch name request =
    command <| Watch name request
