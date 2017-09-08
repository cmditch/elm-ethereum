module Web3.Eth.Contract
    exposing
        ( call
        , send
        , estimateGas
        , getData
        , watch
        , get
        , sentry
        , reset
        , stopWatching
        , pollContract
        , ContractMethod
        )

-- import Web3.Internal exposing (Request)

import Web3 exposing (Retry)
import Web3.Internal exposing (EventRequest, GetDataRequest, contractFuncHelper)
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.EM exposing (eventSentry, watchEvent, stopWatchingEvent)
import BigInt exposing (BigInt)
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


{-
   Contract Methods
-}


type MethodType
    = Call
    | Send
    | EstimateGas


type alias ContractMethod a =
    { abi : Abi
    , contractAddress : Address
    , from : Address
    , gasPrice : BigInt
    , gas : Int
    , method : String
    , params : List Value
    , decoder : Decoder a
    }


type alias RawContractMethod a =
    { abi : String
    , contractAddress : String
    , from : String
    , gasPrice : String
    , gas : Int
    , method : String
    , params : Value
    , expect : Expect a
    }


formatMethod : ContractMethod a -> RawContractMethod a
formatMethod method =
    let
        (Abi abi) =
            method.abi

        (Address contractAddress) =
            method.contractAddress

        (Address from) =
            method.from
    in
        { abi = abi
        , contractAddress = contractAddress
        , from = from
        , gasPrice = BigInt.toString method.gasPrice
        , gas = method.gas
        , method = method.method
        , params = Encode.list method.params
        , expect = expectJson method.decoder
        }


call : ContractMethod a -> Task Error a
call method =
    Native.Web3.contract "call" (formatMethod method)


send : ContractMethod a -> Task Error TxId
send method =
    let
        rawMethod =
            formatMethod method
    in
        Native.Web3.contract "send" { rawMethod | expect = expectJson txIdDecoder }


estimateGas : ContractMethod a -> Task Error Int
estimateGas method =
    let
        rawMethod =
            formatMethod method
    in
        Native.Web3.contract "estimateGas" { rawMethod | expect = expectInt }



-- contract = eval("new web3.eth.Contract(" + request.abi + ",'" + request.contractAddress._0 + "', "{from: request.from._0, gasPrice: request.gasPrice, gas: request.gas}).methods." + request.method + "(request.params)." + callType + "(callback)"
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


getData : Abi -> Hex -> List Value -> Task Error Hex
getData (Abi abi) (Hex data) constructorParams =
    Native.Web3.contractGetData
        { abi = abi
        , data = data
        , constructorParams = Encode.list constructorParams
        }


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
