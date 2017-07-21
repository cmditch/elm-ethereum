module Web3.Eth.Contract
    exposing
        ( call
        , new
        )

import Web3.Eth.Types exposing (Address, Abi, TxParams, ConstructorParams)


call : Abi -> String -> Address -> String
call abi func address =
    "eth.contract("
        ++ abi
        ++ ").at('"
        ++ address
        ++ "')."
        ++ func


new : Abi -> String
new abi =
    "eth.contract("
        ++ abi
        ++ ").new"
