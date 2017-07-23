module Web3.Eth.Contract
    exposing
        ( call
        , deployContract
        )

-- import Web3.Internal exposing (Request)

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Address, Abi, NewContract)
import Task exposing (Task)


call : Abi -> String -> Address -> String
call abi func address =
    "eth.contract("
        ++ abi
        ++ ").at('"
        ++ address
        ++ "')."
        ++ func


deployContract : String -> Task Error NewContract
deployContract evalFunc =
    Native.Web3.deployContract evalFunc
