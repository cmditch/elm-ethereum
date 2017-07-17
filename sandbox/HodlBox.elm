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
    Encode.string """
    [{"constant":true,"inputs":[],"name":"hodlTillBlock","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"releaseTheHodl","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"hodler","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"hodlCountdown","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"hodling","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"isDeholdable","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"withdrawn","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"deposit","outputs":[],"payable":true,"type":"function"},{"inputs":[{"name":"_blocks","type":"uint256"}],"payable":true,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"name":"_isReleased","type":"bool"}],"name":"HodlReleased","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"_isCreated","type":"bool"}],"name":"Hodling","type":"event"}]
    """


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
