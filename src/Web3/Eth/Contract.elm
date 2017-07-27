module Web3.Eth.Contract
    exposing
        ( call
        , deployContract
        , getData
        )

-- import Web3.Internal exposing (Request)

import Web3 exposing (Error)
import Web3.Decoders exposing (expectString)
import Web3.Eth.Types exposing (Address, Abi, NewContract, Bytes)
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


deployContract : String -> Task Error NewContract
deployContract evalFunc =
    Native.Web3.deployContract evalFunc
