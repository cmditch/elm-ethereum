module Web3.Eth.Contract
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



-- deploy : Params -> Task Error Address
--
{-
   Contract Events
-}


once : Address -> Params (EventLog a) -> Task Error (EventLog a)
once (Address contractAddress) params =
    let
        rawParams =
            defaultRawParams params
    in
        toTask (constructEval params Once)
            { rawParams | contractAddress = contractAddress }



--
-- watch : String -> EventRequest -> Cmd msg
-- watch name eventRequest =
--     Web3.EM.watchEvent name eventRequest
--
--
-- stopWatching : String -> Cmd msg
-- stopWatching name =
--     Web3.EM.stopWatchingEvent name
--
--
-- sentry : String -> (String -> msg) -> Sub msg
-- sentry eventId toMsg =
--     Web3.EM.eventSentry eventId toMsg
--
--
-- reset : Cmd msg
-- reset =
--     Web3.EM.reset
--
--
-- pollContract : Retry -> TxId -> Task Error ContractInfo
-- pollContract retryParams (TxId txId) =
--     -- TODO This could be made more general. pollMinedTx
--     Web3.toTask
--         { method = "eth.getTransactionReceipt"
--         , params = Encode.list [ Encode.string txId ]
--         , expect = expectJson contractInfoDecoder
--         , callType = Async
--         , applyScope = Nothing
--         }
--         |> Web3.retry retryParams
--
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
