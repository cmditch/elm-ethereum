effect module Web3.Eth.Contract
    where { command = MyCmd, subscription = MySub }
    exposing
        ( call
        , send
        , estimateMethodGas
        , estimateContractGas
        , encodeMethodABI
        , encodeContractABI
        , subscribe
        , unsubscribe
        , eventSentry
        , once
        , Params
        )

import Native.Web3
import Web3.Internal exposing (constructOptions, decapitalize)
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import BigInt exposing (BigInt)
import Task exposing (Task)
import Dict exposing (Dict)
import Process


type MethodAction
    = Send
    | Call
    | EstimateGas
    | EncodeABI


type ContractAction
    = Methods MethodAction
    | Deploy MethodAction
    | Once


type alias Params a =
    { abi : Abi
    , gasPrice : Maybe BigInt
    , gas : Maybe Int
    , data : Maybe Hex
    , params : List Value
    , methodName : Maybe String
    , decoder : Decoder a
    }



{-
   Contract Methods
-}


call : Address -> Params a -> Task Error a
call (Address contractAddress) params =
    let
        rawParams =
            defaultRawParams params
    in
        toTask (constructEval params <| Methods Call)
            { rawParams | contractAddress = contractAddress }


send : Address -> Address -> Params a -> Task Error TxId
send (Address from) (Address contractAddress) params =
    let
        rawParams =
            defaultRawParams params
    in
        toTask (constructEval params <| Methods Send)
            { rawParams
                | expect = expectJson txIdDecoder
                , from = from
                , contractAddress = contractAddress
            }


estimateMethodGas : Address -> Params a -> Task Error Int
estimateMethodGas (Address contractAddress) params =
    let
        rawParams =
            defaultRawParams params
    in
        toTask (constructEval params <| Methods EstimateGas)
            { rawParams
                | expect = expectInt
                , contractAddress = contractAddress
            }


encodeMethodABI : Params a -> Task Error Hex
encodeMethodABI params =
    let
        rawParams =
            defaultRawParams params
    in
        toTask (constructEval params <| Methods EncodeABI)
            { rawParams
                | expect = expectJson hexDecoder
                , callType = Sync
            }


encodeContractABI : Params Hex -> Task Error Hex
encodeContractABI params =
    let
        rawParams =
            defaultRawParams params
    in
        toTask (constructEval params <| Deploy EncodeABI)
            { rawParams | callType = Sync }


estimateContractGas : Params Int -> Task Error Int
estimateContractGas params =
    toTask (constructEval params <| Deploy EstimateGas)
        (defaultRawParams params)


once : Address -> Params (EventLog a) -> Task Error (EventLog a)
once (Address contractAddress) params =
    let
        rawParams =
            defaultRawParams params
    in
        toTask (constructEval params Once)
            { rawParams | contractAddress = contractAddress }



{-
   Effect Manager
-}
-- COMMANDS


type MyCmd msg
    = Subscribe String String String String
    | Unsubscribe String


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ cmd =
    case cmd of
        Subscribe abi eventName address eventId ->
            Subscribe abi eventName address eventId

        Unsubscribe eventId ->
            Unsubscribe eventId


subscribe : Abi -> String -> ( Address, String ) -> Cmd msg
subscribe (Abi abi) eventName ( Address address, eventId ) =
    command <| Subscribe abi eventName address (address ++ eventId)



{-
   NOTE
   Combining address and eventId to make eventId more unique,
   otherwise you could erroneously subscribe to another event
   with the same name but different address.

-}


unsubscribe : ( Address, String ) -> Cmd msg
unsubscribe ( Address address, eventId ) =
    command <| Unsubscribe (address ++ eventId)



-- SUBSCRIPTIONS


type MySub msg
    = EventSentry String (String -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap method (EventSentry name toMsg) =
    EventSentry name (toMsg >> method)


eventSentry : ( Address, String ) -> (String -> msg) -> Sub msg
eventSentry ( Address address, eventId ) toMsg =
    subscription <| EventSentry (address ++ eventId) toMsg



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
        [] ->
            Task.succeed eventEmittersDict

        (Subscribe abi eventName address eventId) :: rest ->
            case Dict.get eventId eventEmittersDict of
                Just _ ->
                    sendMessagesHelp router rest eventEmittersDict

                Nothing ->
                    createEventEmitter abi address eventName
                        |> Task.andThen
                            (\eventEmitter ->
                                (Process.spawn (eventSubscribe router eventEmitter eventId))
                                    &> Task.succeed (Dict.insert eventId eventEmitter eventEmittersDict)
                            )
                        |> Task.andThen (\newEventEmitters -> sendMessagesHelp router rest newEventEmitters)

        (Unsubscribe eventId) :: rest ->
            case Dict.get eventId eventEmittersDict of
                Just eventEmitter ->
                    Process.spawn (eventUnsubscribe eventEmitter)
                        &> Task.succeed (Dict.remove eventId eventEmittersDict)

                Nothing ->
                    sendMessagesHelp router rest eventEmittersDict


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
        [] ->
            dict

        (EventSentry eventId toMsg) :: rest ->
            buildSubsDict rest (Dict.update eventId (add toMsg) dict)


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



-- Internal


toTask : String -> RawParams a -> Task Error a
toTask =
    Native.Web3.toTask


type alias RawParams a =
    { abi : String
    , contractAddress : String
    , from : String
    , gas : Int
    , gasPrice : String
    , data : String
    , method : String
    , params : Value
    , expect : Expect a
    , callType : CallType
    }


defaultRawParams : Params a -> RawParams a
defaultRawParams contractParams =
    let
        methodName =
            Maybe.withDefault "" contractParams.methodName

        gasPrice =
            Maybe.withDefault (BigInt.fromInt 0) contractParams.gasPrice

        gas =
            Maybe.withDefault 0 contractParams.gas

        (Hex data) =
            Maybe.withDefault (Hex "") contractParams.data

        (Abi abi) =
            contractParams.abi
    in
        { abi = abi
        , contractAddress = ""
        , from = ""
        , gasPrice = BigInt.toString gasPrice
        , gas = gas
        , method = methodName
        , params = Encode.list contractParams.params
        , expect = expectJson contractParams.decoder
        , callType = Async
        , data = data
        }


constructEval : Params a -> ContractAction -> String
constructEval { gas, gasPrice, data } contractMethod =
    let
        gas_ =
            Maybe.map (\_ -> "request.gas") gas

        gasPrice_ =
            Maybe.map (\_ -> "request.gasPrice") gasPrice

        data_ =
            Maybe.map (\_ -> "request.data") data

        options =
            "{ from: request.from, "
                ++ constructOptions [ ( "gas", gas_ ), ( "gasPrice", gasPrice_ ), ( "data", data_ ) ]
                ++ "}"

        base =
            "new web3.eth.Contract(JSON.parse(request.abi), request.contractAddress," ++ options ++ ")"

        callbackIfAsync callType =
            case callType of
                EncodeABI ->
                    "()"

                _ ->
                    "(web3Callback)"
    in
        case contractMethod of
            Methods callType ->
                base
                    ++ ".methods[request.method].apply(web3.eth.Contract, request.params)."
                    ++ (toString callType |> decapitalize)
                    ++ callbackIfAsync callType

            Deploy callType ->
                base
                    ++ ".deploy({arguments: request.params})."
                    ++ (toString callType |> decapitalize)
                    ++ callbackIfAsync callType

            Once ->
                let
                    contract =
                        "var contract = " ++ base ++ ";"

                    callOnce =
                        " return contract.once.apply(contract, [request.method].concat(request.params).concat([web3Callback]) )"
                in
                    "(function (){"
                        ++ contract
                        ++ callOnce
                        ++ "})()"
