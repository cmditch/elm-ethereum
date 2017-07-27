module Web3.Eth
    exposing
        ( getBlockNumber
        , getBlock
        , defaultTxParams
        , estimateGas
        , sendTransaction
        )

{-| Web3.Eth
-}

import Web3 exposing (Error)
import Web3.Eth.Types exposing (..)
import Web3.Decoders exposing (expectInt, expectJson, expectString)
import Web3.Eth.Decoders exposing (blockDecoder)
import Web3.Eth.Encoders exposing (txParamsEncoder)
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


estimateGas : TxParams -> Task Error Int
estimateGas txParams =
    Web3.toTask
        { func = "eth.estimateGas"
        , args = Encode.list [ txParamsEncoder txParams ]
        , expect = expectInt
        }


sendTransaction : TxParams -> Task Error TxId
sendTransaction txParams =
    Web3.toTask
        { func = "eth.sendTransaction"
        , args = Encode.list [ txParamsEncoder txParams ]
        , expect = expectString
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
    , gasPrice = Just 2000000000
    , nonce = Nothing
    }
