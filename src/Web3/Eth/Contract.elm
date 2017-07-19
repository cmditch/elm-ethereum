module Web3.Eth.Contract
    exposing
        ( call
        , sendTransaction
        )

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Address(..), CallData, SendData)
import Task exposing (Task)


call : String -> String -> Address -> String
call abi func (Address address) =
    -- Possibly wrap things up to be type safe.
    -- Abi, Funcs, etc?
    "eth.contract("
        ++ abi
        ++ ").at('"
        ++ address
        ++ "')."
        ++ func


sendTransaction : SendData -> Task Error a
sendTransaction data =
    Native.Web3.contractSend data
