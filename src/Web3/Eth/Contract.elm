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
        )

-- import Web3.Internal exposing (Request)

import Web3 exposing (Error, Retry)
import Web3.Internal exposing (EventRequest, GetDataRequest, contractFuncHelper)
import Web3.Types exposing (..)
import Web3.Eth.Types exposing (..)
import Web3.Decoders exposing (expectString, expectJson)
import Web3.Eth.Decoders exposing (contractInfoDecoder)
import Web3.Eth.Types exposing (Address, Abi, ContractInfo, Bytes, TxId)
import Web3.EM exposing (eventSentry, watchEvent, stopWatchingEvent)
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


-- TODO Refactor 'call' to look like others, not just a string?


call : Abi -> Address -> String -> String
call abi address func =
    contractFuncHelper abi address func


watch : String -> EventRequest -> Cmd msg
watch name eventRequest =
    Web3.EM.watchEvent name eventRequest


stopWatching : String -> Cmd msg
stopWatching name =
    Web3.EM.stopWatchingEvent name


get : Decoder (EventLog args) -> EventRequest -> Task Error (List (EventLog args))
get argDecoder { abi, address, argsFilter, filterParams, eventName } =
    Web3.toTask
        { func = contractFuncHelper abi address eventName
        , args = Encode.list [ argsFilter, filterParams ]
        , expect = expectJson (Decode.list argDecoder)
        , callType = Async
        }


sentry : String -> (String -> msg) -> Sub msg
sentry eventId toMsg =
    Web3.EM.eventSentry eventId toMsg


reset : Cmd msg
reset =
    Web3.EM.reset



-- get : EventRequest -> FilterParams -> Task Error log
-- get eventRequest filterParams =


getData : Abi -> Bytes -> List Value -> Task Error Bytes
getData (Abi abi) (Bytes data) constructorParams =
    Native.Web3.contractGetData
        { abi = abi
        , data = data
        , constructorParams = Encode.list constructorParams
        }


pollContract : Retry -> TxId -> Task Error ContractInfo
pollContract retryParams (TxId txId) =
    -- TODO This could be made more general. pollMinedTx
    Web3.toTask
        { func = "eth.getTransactionReceipt"
        , args = Encode.list [ Encode.string txId ]
        , expect = expectJson contractInfoDecoder
        , callType = Async
        }
        |> Web3.retry retryParams
