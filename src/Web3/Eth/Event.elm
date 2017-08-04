effect module Web3.Eth.Event where { command = MyCmd, subscription = MySub } exposing (MyCmd)

import Dict
import Process
import Task exposing (Task)
import Time exposing (Time)
import Web3.Types exposing (Expect(..))
import Web3.Eth.Types exposing (..)
import Json.Encode as Encode exposing (Value)


-- EVENT REQUEST


type alias EventRequest =
    { abi : Abi
    , address : Address
    , filterParams : Value
    , eventParams : Value
    , id : String
    }


watch : EventRequest -> Cmd msg
watch { abi, address, filterParams, eventName, id } =
    let
        (Abi abi_) =
            abi

        (Address address) =
            address
    in
        Native.Web3.eventWatch



-- subtract_ : Address -> SubFilter -> String -> Cmd msg
-- subtract_ (Address contract) filter id =
--     let
--         filter_ =
--             encodeSubtractFilter filter
--     in
--         Event.watch
--             { abi = lightBoxAbi_
--             , address = contract
--             , filterParams = filter_
--             , eventParams = eventParams_
--             , eventName = "Subtract"
--             , id = id
--             }
-- COMMANDS


type MyCmd msg
    = Watch EventRequest
    | StopWatching String


{-| Send a message to a particular address. You might say something like this:

    send "ws://echo.websocket.org" "Hello!"

**Note:** It is important that you are also subscribed to this address with
`listen` or `keepAlive`. If you are not, the web socket will be created to
send one message and then closed. Not good!

-}
cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ (Watch eventRequest) =
    Watch eventRequest



-- SUBSCRIPTIONS


type MySub a msg
    = Listen (EventRequest a) (EventLog a -> msg)
    | KeepAlive String


{-| Subscribe to any incoming messages on a websocket. You might say something
like this:

    type Msg = Echo String | ...

    subscriptions model =
      listen "ws://echo.websocket.org" Echo

**Note:** If the connection goes down, the effect manager tries to reconnect
with an exponential backoff strategy. Any messages you try to `send` while the
connection is down are queued and will be sent as soon as possible.

-}
listen : EventRequest a -> (EventLog a -> msg) -> Sub msg
listen url tagger =
    subscription (Listen url tagger)


{-| Keep a connection alive, but do not report any messages. This is useful
for keeping a connection open for when you only need to `send` messages. So
you might say something like this:

    subscriptions model =
        keepAlive "ws://echo.websocket.org"

**Note:** If the connection goes down, the effect manager tries to reconnect
with an exponential backoff strategy. Any messages you try to `send` while the
connection is down are queued and will be sent as soon as possible.

-}
keepAlive : String -> Sub msg
keepAlive url =
    subscription (KeepAlive url)


subMap : (a -> b) -> MySub a -> MySub b
subMap func sub =
    case sub of
        Listen url tagger ->
            Listen url (tagger >> func)

        KeepAlive url ->
            KeepAlive url



-- MANAGER


type alias State msg =
    { sockets : SocketsDict
    , queues : QueuesDict
    , subs : SubsDict msg
    }


type alias SocketsDict =
    Dict.Dict String Connection


type alias QueuesDict =
    Dict.Dict String (List String)


type alias SubsDict msg =
    Dict.Dict String (List (String -> msg))


type Connection
    = Opening Int Process.Id
    | Connected WS.WebSocket


init : Task Never (State msg)
init =
    Task.succeed (State Dict.empty Dict.empty Dict.empty)



-- HANDLE APP MESSAGES


(&>) t1 t2 =
    Task.andThen (\_ -> t2) t1


onEffects :
    Platform.Router msg Msg
    -> List (MyCmd msg)
    -> List (MySub msg)
    -> State msg
    -> Task Never (State msg)
onEffects router cmds subs state =
    let
        sendMessagesGetNewQueues =
            sendMessagesHelp cmds state.sockets state.queues

        newSubs =
            buildSubDict subs Dict.empty

        cleanup newQueues =
            let
                newEntries =
                    Dict.union newQueues (Dict.map (\k v -> []) newSubs)

                leftStep name _ getNewSockets =
                    getNewSockets
                        |> Task.andThen
                            (\newSockets ->
                                attemptOpen router 0 name
                                    |> Task.andThen (\pid -> Task.succeed (Dict.insert name (Opening 0 pid) newSockets))
                            )

                bothStep name _ connection getNewSockets =
                    Task.map (Dict.insert name connection) getNewSockets

                rightStep name connection getNewSockets =
                    closeConnection connection &> getNewSockets

                collectNewSockets =
                    Dict.merge leftStep bothStep rightStep newEntries state.sockets (Task.succeed Dict.empty)
            in
                collectNewSockets
                    |> Task.andThen (\newSockets -> Task.succeed (State newSockets newQueues newSubs))
    in
        sendMessagesGetNewQueues
            |> Task.andThen cleanup


sendMessagesHelp : List (MyCmd msg) -> SocketsDict -> QueuesDict -> Task x QueuesDict
sendMessagesHelp cmds socketsDict queuesDict =
    case cmds of
        [] ->
            Task.succeed queuesDict

        (Send name msg) :: rest ->
            case Dict.get name socketsDict of
                Just (Connected socket) ->
                    WS.send socket msg
                        &> sendMessagesHelp rest socketsDict queuesDict

                _ ->
                    sendMessagesHelp rest socketsDict (Dict.update name (add msg) queuesDict)


buildSubDict : List (MySub msg) -> SubsDict msg -> SubsDict msg
buildSubDict subs dict =
    case subs of
        [] ->
            dict

        (Listen name tagger) :: rest ->
            buildSubDict rest (Dict.update name (add tagger) dict)

        (KeepAlive name) :: rest ->
            buildSubDict rest (Dict.update name (Just << Maybe.withDefault []) dict)


add : a -> Maybe (List a) -> Maybe (List a)
add value maybeList =
    case maybeList of
        Nothing ->
            Just [ value ]

        Just list ->
            Just (value :: list)



-- HANDLE SELF MESSAGES


type Msg
    = Receive String String
    | Die String
    | GoodOpen String WS.WebSocket
    | BadOpen String


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router selfMsg state =
    case selfMsg of
        Receive name str ->
            let
                sends =
                    Dict.get name state.subs
                        |> Maybe.withDefault []
                        |> List.map (\tagger -> Platform.sendToApp router (tagger str))
            in
                Task.sequence sends &> Task.succeed state

        Die name ->
            case Dict.get name state.sockets of
                Nothing ->
                    Task.succeed state

                Just _ ->
                    attemptOpen router 0 name
                        |> Task.andThen (\pid -> Task.succeed (updateSocket name (Opening 0 pid) state))

        GoodOpen name socket ->
            case Dict.get name state.queues of
                Nothing ->
                    Task.succeed (updateSocket name (Connected socket) state)

                Just messages ->
                    List.foldl
                        (\msg task -> WS.send socket msg &> task)
                        (Task.succeed (removeQueue name (updateSocket name (Connected socket) state)))
                        messages

        BadOpen name ->
            case Dict.get name state.sockets of
                Nothing ->
                    Task.succeed state

                Just (Opening n _) ->
                    attemptOpen router (n + 1) name
                        |> Task.andThen (\pid -> Task.succeed (updateSocket name (Opening (n + 1) pid) state))

                Just (Connected _) ->
                    Task.succeed state


updateSocket : String -> Connection -> State msg -> State msg
updateSocket name connection state =
    { state | sockets = Dict.insert name connection state.sockets }


removeQueue : String -> State msg -> State msg
removeQueue name state =
    { state | queues = Dict.remove name state.queues }



-- OPENING WEBSOCKETS WITH EXPONENTIAL BACKOFF


attemptOpen : Platform.Router msg Msg -> Int -> String -> Task x Process.Id
attemptOpen router backoff name =
    let
        goodOpen ws =
            Platform.sendToSelf router (GoodOpen name ws)

        badOpen _ =
            Platform.sendToSelf router (BadOpen name)

        actuallyAttemptOpen =
            open name router
                |> Task.andThen goodOpen
                |> Task.onError badOpen
    in
        Process.spawn (after backoff &> actuallyAttemptOpen)


open : String -> Platform.Router msg Msg -> Task WS.BadOpen WS.WebSocket
open name router =
    WS.open name
        { onMessage = \_ msg -> Platform.sendToSelf router (Receive name msg)
        , onClose = \details -> Platform.sendToSelf router (Die name)
        }


after : Int -> Task x ()
after backoff =
    if backoff < 1 then
        Task.succeed ()
    else
        Process.sleep (toFloat (10 * 2 ^ backoff))



-- CLOSE CONNECTIONS


closeConnection : Connection -> Task x ()
closeConnection connection =
    case connection of
        Opening _ pid ->
            Process.kill pid

        Connected socket ->
            WS.close socket
