module Web3.Eth.Contract
    exposing
        ( call
        , getData
        , watch
        , pollContract
        )

-- import Web3.Internal exposing (Request)

import Web3 exposing (Error, Retry)
import Web3.Internal exposing (EventRequest, GetDataRequest)
import Web3.Types exposing (CallType(..))
import Web3.Decoders exposing (expectString, expectJson)
import Web3.Eth.Decoders exposing (contractAddressDecoder)
import Web3.Eth.Types exposing (Address, Abi, ContractInfo, Bytes, TxId)
import Json.Encode as Encode exposing (Value)
import Task exposing (Task)


-- TODO Refactor 'call' to look like others, not just a string?


call : Abi -> String -> Address -> String
call abi func address =
    "eth.contract("
        ++ abi
        ++ ").at('"
        ++ address
        ++ "')."
        ++ func


watch : EventRequest -> Task Error ()
watch eventRequest =
    Native.Web3.watchEvent eventRequest


stopWatching : Task Error a
stopWatching =
    Native.Web3.stopEvent


getData : Abi -> Bytes -> List Value -> Task Error Bytes
getData abi data constructorParams =
    Native.Web3.contractGetData
        { abi = abi
        , data = data
        , constructorParams = Encode.list constructorParams
        }


pollContract : Retry -> TxId -> Task Error ContractInfo
pollContract retryParams txId =
    Web3.toTask
        { func = "eth.getTransactionReceipt"
        , args = Encode.list [ Encode.string txId ]
        , expect = expectJson contractAddressDecoder
        , callType = Async
        }
        |> Web3.retry retryParams
