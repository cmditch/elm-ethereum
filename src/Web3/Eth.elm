module Web3.Eth
    exposing
        ( getBlockNumber
        , getBlock
        , defaultTxParams
        )

{-| Web3.Eth
-}

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Block, TxReceipt, TxId, TxParams)
import Web3.Decoders exposing (expectInt, expectJson)
import Web3.Eth.Decoders exposing (blockDecoder)
import Json.Encode as Encode
import Task exposing (Task)


getBlockNumber : Task Error Int
getBlockNumber =
    Web3.toTask
        { func = "eth.getBlockNumber"
        , args = Encode.list []
        , expect = expectInt
        }


getBlock : Int -> Task Error Block
getBlock blockNum =
    Web3.toTask
        { func = "eth.getBlock"
        , args = Encode.list [ Encode.int blockNum ]
        , expect = expectJson blockDecoder
        }



-- getTransactionReceipt : TxId -> Task Error TxReceipt
-- getTransactionReceipt txId =
--     Web3.toTask
--         { func = "eth.getBlockNumber"
--         , args = Encode.list []
--         , expect = expectInt
--         }


defaultTxParams : TxParams
defaultTxParams =
    { from = Nothing
    , to = Nothing
    , value = Nothing
    , data = Nothing
    , gas = Nothing
    , gasPrice = Just 1000000000
    , nonce = Nothing
    }
