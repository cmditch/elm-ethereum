-- d0e30db0 deposit()
-- 77a1ec4b hodlCountdown()
-- 0c8b29ae hodlTillBlock()
-- 3bc58532 hodler()
-- 7844ce81 hodling()
-- bc7e8d3c isDeholdable()
-- 2b1e5016 releaseTheHodl()
-- c80ec522 withdrawn()


module HodlBox exposing (..)

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Address, TxParams, TxId)
import Web3.Eth.Contract as Contract exposing (sendTransaction, call)
import BigInt exposing (BigInt)
import Task exposing (Task)
import Json.Encode as Encode exposing (Value)


abi : Value
abi =
    Encode.string "[]"


deposit : Address -> TxParams -> Task Error TxId
deposit address txParams =
    Contract.sendTransaction
        { abi = abi
        , address = address
        , params = txParams
        , args = Nothing
        , data = Nothing
        }


hodler : Address -> Task Error Address
hodler address =
    Contract.call
        { abi = abi
        , address = address
        , args = Nothing
        }


hodling : Address -> Task Error BigInt
hodling address =
    Contract.call
        { abi = abi
        , address = address
        , args = Nothing
        }
