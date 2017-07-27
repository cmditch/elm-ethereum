module Web3.Eth.Contract
    exposing
        ( call
        , deployContract
        , getData
        , pollForAddress
        )

-- import Web3.Internal exposing (Request)

import Web3 exposing (Error, Retry)
import Web3.Decoders exposing (expectString, expectJson)
import Web3.Eth.Decoders exposing (contractAddressDecoder)
import Web3.Eth.Types exposing (Address, Abi, NewContract, Bytes, TxId)
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
        }


pollForAddress : Retry -> TxId -> Task Error Address
pollForAddress retry txId =
    Web3.toTask
        { func = "eth.getTransactionReceipt"
        , args = Encode.list [ Encode.string txId ]
        , expect = expectJson contractAddressDecoder
        }


deployContract : String -> Task Error NewContract
deployContract evalFunc =
    Native.Web3.deployContract evalFunc
