effect module Web3.Eth.Contract
    where { command = MyCmd, subscription = MySub }
    exposing
        ( call
        , send
        , estimateMethodGas
        , estimateContractGas
        , encodeMethodABI
        , encodeContractABI
        , once
        , Params
        )

-- import Web3.Internal exposing (Request)

import Web3.Internal exposing (EventRequest, constructOptions, decapitalize)
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import BigInt exposing (BigInt)
import Dict exposing (Dict)
import Process
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


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



{-
   Effect Manager
-}
-- COMMANDS


type MyCmd msg
    = Once String String (String -> msg) String


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap tagger cmd =
    case cmd of
        Once abi eventName toAppMsg address ->
            Once abi eventName (toAppMsg >> tagger) address


once : Abi -> String -> (String -> msg) -> Address -> Cmd msg
once (Abi abi) eventName toAppMsg (Address address) =
    command <| Once abi eventName toAppMsg address



-- SUBSCRIPTIONS


type MySub msg
    = EventSentry String (String -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap method (EventSentry name toMsg) =
    EventSentry name (toMsg >> method)


eventSentry : String -> (String -> msg) -> Sub msg
eventSentry eventId toMsg =
    subscription (EventSentry eventId toMsg)



-- MANAGER


type Contract
    = Contract


type alias State msg =
    { subs : SubsDict msg
    , contracts : ContractsDict
    }


type alias SubsDict msg =
    Dict.Dict String (List (String -> msg))


type alias ContractsDict =
    Dict.Dict String Contract


init : Task Never (State msg)
init =
    Task.succeed (State Dict.empty Dict.empty)


onEffects : Platform.Router msg Msg -> List (MyCmd msg) -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router cmds subs state =
    let
        sendMessages =
            sendMessagesHelp router cmds state.contracts

        newSubs =
            -- buildSubsDict subs
            Dict.empty
    in
        sendMessages
            |> Task.andThen (\web3EventDict -> State newSubs web3EventDict |> Task.succeed)


sendMessagesHelp : Platform.Router msg Msg -> List (MyCmd msg) -> ContractsDict -> Task Never ContractsDict
sendMessagesHelp router cmds contractsDict =
    case cmds of
        [] ->
            Task.succeed contractsDict

        (Once abi eventName toMsg address) :: rest ->
            case Dict.get address contractsDict of
                Just contract ->
                    Process.spawn (watchEventOnce router contract eventName toMsg)
                        |> Task.andThen (\_ -> sendMessagesHelp router rest contractsDict)

                Nothing ->
                    createContract abi address
                        |> Task.andThen (\contract -> Task.succeed (Dict.insert address contract contractsDict))
                        |> Task.andThen
                            (\newContractsDict ->
                                sendMessagesHelp router ((Once abi eventName toMsg address) :: rest) newContractsDict
                            )


createContract : String -> String -> Task Never Contract
createContract =
    Native.Web3.createContract


watchEventOnce : Platform.Router msg Msg -> Contract -> String -> (String -> msg) -> Task Never ()
watchEventOnce router contract eventName toAppMsg =
    Native.Web3.watchEventOnce
        contract
        eventName
        (\log -> Platform.sendToApp router (toAppMsg log))



--
-- buildSubsDict : List (MySub msg) -> SubsDict msg -> SubsDict msg
-- buildSubsDict subs dict =
--     case subs of
--         [] ->
--             dict
--
--         (EventSentry name toMsg) :: rest ->
--             buildSubsDict rest (Dict.update name (add toMsg) dict)
--
-- add : a -> Maybe (List a) -> Maybe (List a)
-- add value maybeList =
--     case maybeList of
--         Nothing ->
--             Just [ value ]
--
--         Just list ->
--             Just (value :: list)


type Msg
    = RecieveOnce String String


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router (RecieveOnce name log) state =
    -- let
    --     sends =
    --         Dict.get name state.subs
    --             |> Maybe.withDefault []
    --             |> List.map (\tagger -> Platform.sendToApp router (tagger log))
    -- in
    -- Task.sequence sends &>
    Task.succeed state



-- Internal


toTask : String -> RawParams a -> Task Error a
toTask =
    Native.Web3.toTask


type MethodAction
    = Send
    | Call
    | EstimateGas
    | EncodeABI


type ContractAction
    = Methods MethodAction
    | Deploy MethodAction


type alias Params a =
    { abi : Abi
    , gasPrice : Maybe BigInt
    , gas : Maybe Int
    , data : Maybe Hex
    , params : List Value
    , methodName : Maybe String
    , decoder : Decoder a
    }


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


(&>) : Task a x -> Task a b -> Task a b
(&>) t1 t2 =
    t1 |> Task.andThen (\_ -> t2)
