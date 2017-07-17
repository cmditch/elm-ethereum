-- d0e30db0 deposit()
-- 77a1ec4b hodlCountdown()
-- 0c8b29ae hodlTillBlock()
-- 3bc58532 hodler()
-- 7844ce81 hodling()
-- bc7e8d3c isDeholdable()
-- 2b1e5016 releaseTheHodl()
-- c80ec522 withdrawn()


module HodlBox exposing (..)

import Web3 exposing (Address, Error)
import Web3.Eth.Types exposing (TxParams, TxId)
import Web3.Eth.Contract exposing (sendTransaction, call)
import BigInt exposing (BigInt)
import Task exposing (Task)
import Json.Encode as Encode exposing (Value)


abi : Value
abi =
    Encode.string "[]"


deposit : Result Error TxId -> Address -> TxParams -> Task Error TxId
deposit msg address txParams =
    Web3.Eth.Contract.sendTransaction msg
        { abi = abi
        , address = address
        , params = txParams
        , args = Nothing
        , data = Nothing
        }


hodler : Address -> Result Error Address -> Task Error Address
hodler address msg =
    Web3.Eth.Contract.call msg
        { abi = abi
        , address = address
        , args = Nothing
        }


hodling : Address -> Result Error BigInt -> Task Error BigInt
hodling address msg =
    Web3.Eth.Contract.call msg
        { abi = abi
        , address = address
        , args = Nothing
        }
