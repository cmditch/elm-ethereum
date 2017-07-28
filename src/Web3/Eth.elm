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
import Web3.Types exposing (CallType(..), Hex)
import Web3.Eth.Types exposing (..)
import Web3.Decoders exposing (expectInt, expectBool, expectJson, expectString, expectBigInt)
import Web3.Eth.Decoders exposing (blockDecoder, syncStatusDecoder, txObjDecoder, blockTxObjDecoder, txReceiptDecoder)
import Web3.Eth.Encoders exposing (txParamsEncoder)
import Json.Encode as Encode
import Json.Decode as Decode
import Task exposing (Task)
import BigInt exposing (BigInt)


getSyncing : Task Error (Maybe SyncStatus)
getSyncing =
    Web3.toTask
        { func = "eth.getSyncing"
        , args = Encode.list []
        , expect = expectJson (Decode.maybe syncStatusDecoder)
        , callType = Async
        }



-- Tricky one to implement, maybe ports only?
-- isSyncing : Task Error (Maybe SyncStatus)
-- isSyncing =
-- https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethissyncing


getCoinbase : Task Error Address
getCoinbase =
    Web3.toTask
        { func = "eth.getCoinbase"
        , args = Encode.list []
        , expect = expectString
        , callType = Async
        }


coinbase : Task Error Address
coinbase =
    getCoinbase


getMining : Task Error Bool
getMining =
    Web3.toTask
        { func = "eth.getMining"
        , args = Encode.list []
        , expect = expectBool
        , callType = Async
        }


getHashrate : Task Error Int
getHashrate =
    Web3.toTask
        { func = "eth.getHashrate"
        , args = Encode.list []
        , expect = expectInt
        , callType = Async
        }


getGasPrice : Task Error BigInt
getGasPrice =
    Web3.toTask
        { func = "eth.getGasPrice"
        , args = Encode.list []
        , expect = expectBigInt
        , callType = Async
        }


getAccounts : Task Error (List Address)
getAccounts =
    Web3.toTask
        { func = "eth.getAccounts"
        , args = Encode.list []
        , expect = expectJson (Decode.list Decode.string)
        , callType = Async
        }


accounts : Task Error (List Address)
accounts =
    getAccounts


getBlockNumber : Task Error Int
getBlockNumber =
    Web3.toTask
        { func = "eth.getBlockNumber"
        , args = Encode.list []
        , expect = expectInt
        , callType = Async
        }


getBalance : Address -> Task Error BigInt
getBalance address =
    Web3.toTask
        { func = "eth.getBalance"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBigInt
        , callType = Async
        }


getStorageAt : Address -> Int -> Task Error Hex
getStorageAt =
    getStorageAtBlock Latest


getStorageAtBlock : BlockId -> Address -> Int -> Task Error Hex
getStorageAtBlock blockId address position =
    Web3.toTask
        { func = "eth.getStorageAt"
        , args = Encode.list [ Encode.string address, Encode.int position, getBlockIdValue blockId ]
        , expect = expectString
        , callType = Async
        }


getCode : Address -> Task Error Bytes
getCode =
    getCodeAtBlock Latest


getCodeAtBlock : BlockId -> Address -> Task Error Bytes
getCodeAtBlock blockId address =
    Web3.toTask
        { func = "eth.getStorageAt"
        , args = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectString
        , callType = Async
        }


getBlock : BlockId -> Task Error Block
getBlock blockId =
    Web3.toTask
        { func = "eth.getBlock"
        , args = Encode.list [ getBlockIdValue blockId, Encode.bool False ]
        , expect = expectJson blockDecoder
        , callType = Async
        }



-- TODO Change name of BlockTxObjs type?


getBlockTxObjs : BlockId -> Task Error BlockTxObjs
getBlockTxObjs blockId =
    Web3.toTask
        { func = "eth.getBlock"
        , args = Encode.list [ getBlockIdValue blockId, Encode.bool True ]
        , expect = expectJson blockTxObjDecoder
        , callType = Async
        }


getBlockTransactionCount : BlockId -> Task Error Int
getBlockTransactionCount blockId =
    Web3.toTask
        { func = "eth.getBlockTransactionCount"
        , args = Encode.list [ getBlockIdValue blockId ]
        , expect = expectInt
        , callType = Async
        }


getUncle : BlockId -> Int -> Task Error Block
getUncle blockId index =
    Web3.toTask
        { func = "eth.getUncle"
        , args = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool False ]
        , expect = expectJson blockDecoder
        , callType = Async
        }


getUncleTxObjs : BlockId -> Int -> Task Error BlockTxObjs
getUncleTxObjs blockId index =
    Web3.toTask
        { func = "eth.getUncle"
        , args = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool True ]
        , expect = expectJson blockTxObjDecoder
        , callType = Async
        }


getTransaction : TxId -> Task Error TxObj
getTransaction txId =
    Web3.toTask
        { func = "eth.getTransaction"
        , args = Encode.list [ Encode.string txId ]
        , expect = expectJson txObjDecoder
        , callType = Async
        }


getTransactionFromBlock : BlockId -> Int -> Task Error TxObj
getTransactionFromBlock blockId index =
    Web3.toTask
        { func = "eth.getTransactionFromBlock"
        , args = Encode.list [ getBlockIdValue blockId, Encode.int index ]
        , expect = expectJson txObjDecoder
        , callType = Async
        }


getTransactionReceipt : TxId -> Task Error TxReceipt
getTransactionReceipt txId =
    Web3.toTask
        { func = "eth.getTransactionReceipt"
        , args = Encode.list [ Encode.string txId ]
        , expect = expectJson txReceiptDecoder
        , callType = Async
        }


getTransactionCount : Address -> Task Error Int
getTransactionCount =
    getTransactionCountAtBlock Latest


getTransactionCountAtBlock : BlockId -> Address -> Task Error Int
getTransactionCountAtBlock blockId address =
    Web3.toTask
        { func = "eth.getTransactionCount"
        , args = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectInt
        , callType = Async
        }


sendTransaction : TxParams -> Task Error TxId
sendTransaction txParams =
    Web3.toTask
        { func = "eth.sendTransaction"
        , args = Encode.list [ txParamsEncoder txParams ]
        , expect = expectString
        , callType = Async
        }


sendRawTransaction : Bytes -> Task Error TxId
sendRawTransaction signedData =
    Web3.toTask
        { func = "eth.sendRawTransaction"
        , args = Encode.list [ Encode.string signedData ]
        , expect = expectString
        , callType = Async
        }


sign : Address -> Bytes -> Task Error Bytes
sign address bytes =
    Web3.toTask
        { func = "eth.sign"
        , args = Encode.list [ Encode.string address, Encode.string bytes ]
        , expect = expectString
        , callType = Async
        }


call : TxParams -> Task Error TxId
call =
    callAtBlock Latest


callAtBlock : BlockId -> TxParams -> Task Error TxId
callAtBlock blockId txParams =
    Web3.toTask
        { func = "eth.call"
        , args = Encode.list [ txParamsEncoder txParams, getBlockIdValue blockId ]
        , expect = expectString
        , callType = Async
        }


estimateGas : TxParams -> Task Error Int
estimateGas txParams =
    Web3.toTask
        { func = "eth.estimateGas"
        , args = Encode.list [ txParamsEncoder txParams ]
        , expect = expectInt
        , callType = Async
        }


defaultTxParams : TxParams
defaultTxParams =
    { from = Nothing
    , to = Nothing
    , value = Nothing
    , data = Nothing
    , gas = Nothing
    , gasPrice = Just 20000000000
    , nonce = Nothing
    }


getBlockIdValue : BlockId -> Encode.Value
getBlockIdValue blockId =
    case blockId of
        BlockNum number ->
            Encode.int number

        BlockHash hash ->
            Encode.string hash

        Earliest ->
            Encode.string "earliest"

        Latest ->
            Encode.string "latest"

        Pending ->
            Encode.string "pending"
