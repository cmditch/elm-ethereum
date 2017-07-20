module Web3.Eth.Contract
    exposing
        ( call
        , sendTransaction
        )

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Address(..), Abi(..), CallData, SendData)
import Task exposing (Task)


call : Abi -> String -> Address -> String
call (Abi abi) func (Address address) =
    -- Possibly wrap things up to be type safe.
    -- type Abi, type Web3Func, etc?
    "eth.contract("
        ++ abi
        ++ ").at('"
        ++ address
        ++ "')."
        ++ func


sendTransaction : SendData -> Task Error a
sendTransaction data =
    Native.Web3.contractSend data
