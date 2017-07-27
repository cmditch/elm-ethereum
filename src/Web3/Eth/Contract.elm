module Web3.Eth.Contract
    exposing
        ( call
        , getData
        , pollContract
        )

-- import Web3.Internal exposing (Request)

import Web3 exposing (Error, Retry)
import Web3.Types exposing (CallType(..))
import Web3.Decoders exposing (expectString, expectJson)
import Web3.Eth.Decoders exposing (contractAddressDecoder)
import Web3.Eth.Types exposing (Address, Abi, ContractInfo, Bytes, TxId)
import Json.Encode as Encode exposing (Value)
import Task exposing (Task)


call : Abi -> String -> Address -> String
call abi func address =
    "eth.contract("
        ++ abi
        ++ ").at('"
        ++ address
        ++ "')."
        ++ func


getData : Abi -> Bytes -> List Value -> Task Error Bytes
getData abi data constructorParams =
    Web3.toTask
        { func = "eth.contract('" ++ abi ++ "').getData"
        , args = Encode.list <| constructorParams ++ [ Encode.object [ ( "data", Encode.string data ) ] ]
        , expect = expectString
        , callType = Sync
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
