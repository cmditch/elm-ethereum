module Web3.Eth.Contract
    exposing
        ( call
        , getData
        , watch
        , stopWatching
        , pollContract
        )

-- import Web3.Internal exposing (Request)

import Web3 exposing (Error, Retry)
import Web3.Internal exposing (EventRequest, GetDataRequest)
import Web3.Types exposing (..)
import Web3.Eth.Types exposing (..)
import Web3.Decoders exposing (expectString, expectJson)
import Web3.Eth.Decoders exposing (contractInfoDecoder)
import Web3.Eth.Types exposing (Address, Abi, ContractInfo, Bytes, TxId)
import Json.Encode as Encode exposing (Value)
import Task exposing (Task)


-- TODO Refactor 'call' to look like others, not just a string?


call : Abi -> String -> Address -> String
call (Abi abi) func (Address address) =
    "eth.contract("
        ++ abi
        ++ ").at('"
        ++ address
        ++ "')."
        ++ func


watch : EventRequest -> Task Error ()
watch eventRequest =
    let
        (Abi abi) =
            eventRequest.abi

        (Address address) =
            eventRequest.address

        portAndEventName =
            Encode.string eventRequest.eventName
    in
        Native.Web3.eventManager Watch
            { eventRequest
                | abi = abi
                , address = address
                , eventName = portAndEventName
            }


stopWatching : String -> Task Error ()
stopWatching portAndEventName =
    Native.Web3.eventManager StopWatching
        { portAndEventName = Encode.string portAndEventName }


getData : Abi -> Bytes -> List Value -> Task Error Bytes
getData (Abi abi) (Bytes data) constructorParams =
    Native.Web3.contractGetData
        { abi = abi
        , data = data
        , constructorParams = Encode.list constructorParams
        }


pollContract : Retry -> TxId -> Task Error ContractInfo
pollContract retryParams (TxId txId) =
    Web3.toTask
        { func = "eth.getTransactionReceipt"
        , args = Encode.list [ Encode.string txId ]
        , expect = expectJson contractInfoDecoder
        , callType = Async
        }
        |> Web3.retry retryParams
