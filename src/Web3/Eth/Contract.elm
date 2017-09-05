module Web3.Eth.Contract
    exposing
        ( call
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
import Web3.Decoders exposing (expectString, expectJson, contractInfoDecoder)
import Web3.EM exposing (eventSentry, watchEvent, stopWatchingEvent)
import BigInt exposing (BigInt)
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


{-
   Contract Methods
-}


type alias ContractMethod a =
    { abi : String
    , contractAddress : Address
    , from : Address
    , gasPrice : BigInt
    , gas : Int
    , method : String
    , params : List Value
    , expect : Expect a
    }


call : ContractMethod a -> Task Error a
call method =
    Native.Web3.contract "call" method


send : ContractMethod a -> Task Error a
send method =
    Native.Web3.contract "send" method


estimateGas : ContractMethod a -> Task Error Int
estimateGas method =
    Native.Web3.contract "estimateGas" method



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
