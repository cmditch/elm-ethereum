module Web3.Eth.Contract
    exposing
        ( call
        , send
        , estimateGas
        , methodData
          -- , contractData
        , watch
        , get
        , sentry
        , reset
        , stopWatching
        , pollContract
        , Params
        )

-- import Web3.Internal exposing (Request)

import Web3 exposing (Retry)
import Web3.Internal exposing (EventRequest, GetDataRequest, contractFuncHelper, decapitalize)
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.EM exposing (eventSentry, watchEvent, stopWatchingEvent)
import BigInt exposing (BigInt)
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


{-
   Types
-}


type alias Params a =
    { abi : Abi
    , gasPrice : BigInt
    , gas : Int
    , params : List Value
    , decoder : Decoder a
    , methodName : Maybe String
    }



{-
   Contract Methods
-}


evalHelper : ContractAction -> String
evalHelper contractMethod =
    let
        base =
            "new web3.eth.Contract(JSON.parse(request.abi), request.contractAddress,"
                ++ "{from: request.from, gasPrice: request.gasPrice, gas: request.gas})"
    in
        case contractMethod of
            Method callType ->
                let
                    callbackIfAsync =
                        case callType of
                            EncodeABI ->
                                "()"

                            _ ->
                                "(web3Callback)"
                in
                    base
                        ++ ".methods[request.method].apply(null, request.params)."
                        ++ (toString callType |> decapitalize)
                        ++ callbackIfAsync

            Event ->
                base
                    ++ "//under construction//"

            ContractData ->
                base
                    ++ ".deploy({data: request.data, arguments: request.params}).encodeABI()"

            DeployCost ->
                base
                    ++ ".deploy({data: request.data, arguments: request.params}).estimateGas(web3Callback)"


call : Address -> Params a -> Task Error a
call (Address contractAddress) params =
    let
        rawMethod_ =
            formatMethod params

        rawMethod =
            { rawMethod_ | contractAddress = contractAddress }
    in
        Native.Web3.contract (evalHelper <| Method Call) rawMethod


send : Address -> Address -> Params a -> Task Error TxId
send (Address from) (Address contractAddress) params =
    let
        rawMethod_ =
            formatMethod params

        rawMethod =
            { rawMethod_
                | expect = expectJson txIdDecoder
                , from = from
                , contractAddress = contractAddress
            }
    in
        Native.Web3.contract (evalHelper <| Method Send) rawMethod


estimateGas : Address -> Params a -> Task Error Int
estimateGas (Address contractAddress) params =
    let
        rawMethod_ =
            formatMethod params

        rawMethod =
            { rawMethod_ | expect = expectJson txIdDecoder, contractAddress = contractAddress }
    in
        Native.Web3.contract (evalHelper <| Method EstimateGas) { rawMethod | expect = expectInt }


methodData : Params a -> Task Error Hex
methodData params =
    let
        rawMethod_ =
            formatMethod params

        rawMethod =
            { rawMethod_ | expect = expectJson hexDecoder, callType = Sync }
    in
        Native.Web3.contract (evalHelper <| Method EncodeABI) { rawMethod | expect = expectJson hexDecoder }



-- contractData : Hex -> List Value -> Task Error Hex
-- contractData (Hex contractData) params =
--
-- deployCost : Hex ->
-- deploy : TxParams -> List Value -> Task Error Address
-- deploy txParams args =
{-
   Contract Events
-}


watch : String -> EventRequest -> Cmd msg
watch name eventRequest =
    Web3.EM.watchEvent name eventRequest


stopWatching : String -> Cmd msg
stopWatching name =
    Web3.EM.stopWatchingEvent name


get : Decoder log -> EventRequest -> Task Error (List log)
get argDecoder { abi, address, argsFilter, filterParams, eventName } =
    Web3.getEvent
        { method = contractFuncHelper abi address eventName
        , params = Encode.list [ argsFilter, filterParams ]
        , expect = expectJson (Decode.list argDecoder)
        , callType = Async
        }


sentry : String -> (String -> msg) -> Sub msg
sentry eventId toMsg =
    Web3.EM.eventSentry eventId toMsg


reset : Cmd msg
reset =
    Web3.EM.reset


pollContract : Retry -> TxId -> Task Error ContractInfo
pollContract retryParams (TxId txId) =
    -- TODO This could be made more general. pollMinedTx
    Web3.toTask
        { method = "eth.getTransactionReceipt"
        , params = Encode.list [ Encode.string txId ]
        , expect = expectJson contractInfoDecoder
        , callType = Async
        }
        |> Web3.retry retryParams



-- Internal


type MethodAction
    = Send
    | Call
    | EstimateGas
    | EncodeABI


type ContractAction
    = Method MethodAction
    | Event
    | ContractData
    | DeployCost


type alias RawParams a =
    { abi : String
    , contractAddress : String
    , from : String
    , gasPrice : String
    , gas : Int
    , method : String
    , params : Value
    , expect : Expect a
    , callType : CallType
    }


formatMethod : Params a -> RawParams a
formatMethod contractParams =
    let
        methodName =
            Maybe.withDefault "" contractParams.methodName

        (Abi abi) =
            contractParams.abi
    in
        { abi = abi
        , contractAddress = ""
        , from = ""
        , gasPrice = BigInt.toString contractParams.gasPrice
        , gas = contractParams.gas
        , method = methodName
        , params = Encode.list contractParams.params
        , expect = expectJson contractParams.decoder
        , callType = Async
        }
