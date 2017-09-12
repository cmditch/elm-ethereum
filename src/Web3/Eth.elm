module Web3.Eth
    exposing
        ( isSyncing
        , getCoinbase
        , getHashrate
        , getGasPrice
        , getAccounts
        , isMining
        , getNetworkType
        , getBlockNumber
        , getBalance
        , getStorageAt
        , getCode
        , getBlock
        , getBlockTxObjs
        , getBlockTransactionCount
        , getUncle
        , getBlockUncleCount
        , getTransaction
        , estimateGas
        , sendTransaction
        , sendSignedTransaction
        , getId
        , defaultTxParams
        , defaultFilterParams
        )

{-| Web3.Eth
-}

import Web3
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (encodeTxParams, getBlockIdValue, encodeBytes)
import Json.Encode as Encode
import Json.Decode as Decode
import Task exposing (Task)
import BigInt exposing (BigInt)


isSyncing : Task Error (Maybe SyncStatus)
isSyncing =
    Web3.toTask
        { method = "eth.isSyncing"
        , params = Encode.list []
        , expect = expectJson (Decode.maybe syncStatusDecoder)
        , callType = Async
        , applyScope = Nothing
        }



{-
   Implement within Effect Manager.
   NOTE Doesn't seem to work within MetaMask!
   isSyncing : Task Error (Maybe SyncStatus)
-}


getCoinbase : Task Error Address
getCoinbase =
    Web3.toTask
        { method = "eth.getCoinbase"
        , params = Encode.list []
        , expect = expectJson addressDecoder
        , callType = Async
        , applyScope = Nothing
        }


isMining : Task Error Bool
isMining =
    Web3.toTask
        { method = "eth.isMining"
        , params = Encode.list []
        , expect = expectBool
        , callType = Async
        , applyScope = Nothing
        }


getHashrate : Task Error Int
getHashrate =
    Web3.toTask
        { method = "eth.getHashrate"
        , params = Encode.list []
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getGasPrice : Task Error BigInt
getGasPrice =
    Web3.toTask
        { method = "eth.getGasPrice"
        , params = Encode.list []
        , expect = expectBigInt
        , callType = Async
        , applyScope = Nothing
        }


getAccounts : Task Error (List Address)
getAccounts =
    Web3.toTask
        { method = "eth.getAccounts"
        , params = Encode.list []
        , expect = expectJson (Decode.list addressDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getBlockNumber : Task Error BlockId
getBlockNumber =
    Web3.toTask
        { method = "eth.getBlockNumber"
        , params = Encode.list []
        , expect = expectJson blockNumDecoder
        , callType = Async
        , applyScope = Nothing
        }


getBalance : Address -> Task Error BigInt
getBalance (Address address) =
    Web3.toTask
        { method = "eth.getBalance"
        , params = Encode.list [ Encode.string address ]
        , expect = expectBigInt
        , callType = Async
        , applyScope = Nothing
        }


getStorageAt : Address -> Int -> Task Error Hex
getStorageAt =
    getStorageAtBlock Latest


getStorageAtBlock : BlockId -> Address -> Int -> Task Error Hex
getStorageAtBlock blockId (Address address) position =
    Web3.toTask
        { method = "eth.getStorageAt"
        , params = Encode.list [ Encode.string address, Encode.int position, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


getCode : Address -> Task Error Hex
getCode =
    getCodeAtBlock (BlockNum 320)


getCodeAtBlock : BlockId -> Address -> Task Error Hex
getCodeAtBlock blockId (Address address) =
    Web3.toTask
        { method = "eth.getStorageAt"
        , params = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


getBlock : BlockId -> Task Error (Block TxId)
getBlock blockId =
    Web3.toTask
        { method = "eth.getBlock"
        , params = Encode.list [ getBlockIdValue blockId, Encode.bool False ]
        , expect = expectJson blockTxIdDecoder
        , callType = Async
        , applyScope = Nothing
        }


getBlockTxObjs : BlockId -> Task Error (Block TxObj)
getBlockTxObjs blockId =
    Web3.toTask
        { method = "eth.getBlock"
        , params = Encode.list [ getBlockIdValue blockId, Encode.bool True ]
        , expect = expectJson blockTxObjDecoder
        , callType = Async
        , applyScope = Nothing
        }


getBlockTransactionCount : BlockId -> Task Error Int
getBlockTransactionCount blockId =
    Web3.toTask
        { method = "eth.getTransactionCount"
        , params = Encode.list [ getBlockIdValue blockId ]
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getBlockUncleCount : BlockId -> Task Error Int
getBlockUncleCount blockId =
    Web3.toTask
        { method = "eth.getBlockUncleCount"
        , params = Encode.list [ getBlockIdValue blockId ]
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getUncle : BlockId -> Int -> Task Error (Maybe (Block TxId))
getUncle blockId index =
    Web3.toTask
        { method = "eth.getUncle"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool False ]
        , expect = expectJson (Decode.maybe blockTxIdDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getUncleTxObjs : BlockId -> Int -> Task Error (Block TxObj)
getUncleTxObjs blockId index =
    Web3.toTask
        { method = "eth.getUncle"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool True ]
        , expect = expectJson blockTxObjDecoder
        , callType = Async
        , applyScope = Nothing
        }


getTransaction : TxId -> Task Error TxObj
getTransaction (TxId txId) =
    Web3.toTask
        { method = "eth.getTransaction"
        , params = Encode.list [ Encode.string txId ]
        , expect = expectJson txObjDecoder
        , callType = Async
        , applyScope = Nothing
        }


getTransactionFromBlock : BlockId -> Int -> Task Error TxObj
getTransactionFromBlock blockId index =
    Web3.toTask
        { method = "eth.getTransactionFromBlock"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index ]
        , expect = expectJson txObjDecoder
        , callType = Async
        , applyScope = Nothing
        }


getTransactionReceipt : TxId -> Task Error TxReceipt
getTransactionReceipt (TxId txId) =
    Web3.toTask
        { method = "eth.getTransactionReceipt"
        , params = Encode.list [ Encode.string txId ]
        , expect = expectJson txReceiptDecoder
        , callType = Async
        , applyScope = Nothing
        }


getTransactionCount : Address -> Task Error Int
getTransactionCount =
    getTransactionCountAtBlock Latest


getTransactionCountAtBlock : BlockId -> Address -> Task Error Int
getTransactionCountAtBlock blockId (Address address) =
    Web3.toTask
        { method = "eth.getTransactionCount"
        , params = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


sendTransaction : TxParams -> Task Error TxId
sendTransaction txParams =
    Web3.toTask
        { method = "eth.sendTransaction"
        , params = Encode.list [ encodeTxParams txParams ]
        , expect = expectJson txIdDecoder
        , callType = Async
        , applyScope = Nothing
        }


sendSignedTransaction : Hex -> Task Error TxId
sendSignedTransaction (Hex signedData) =
    Web3.toTask
        { method = "eth.sendSignedTransaction"
        , params = Encode.list [ Encode.string signedData ]
        , expect = expectJson txIdDecoder
        , callType = Async
        , applyScope = Nothing
        }


sign : Address -> Hex -> Task Error Bytes
sign (Address address) (Hex data) =
    Web3.toTask
        { method = "eth.sign"
        , params = Encode.list [ Encode.string address, Encode.string data ]
        , expect = expectJson bytesDecoder
        , callType = Async
        , applyScope = Nothing
        }


call : TxParams -> Task Error TxId
call =
    callAtBlock Latest


callAtBlock : BlockId -> TxParams -> Task Error TxId
callAtBlock blockId txParams =
    Web3.toTask
        { method = "eth.call"
        , params = Encode.list [ encodeTxParams txParams, getBlockIdValue blockId ]
        , expect = expectJson txIdDecoder
        , callType = Async
        , applyScope = Nothing
        }


estimateGas : TxParams -> Task Error Int
estimateGas txParams =
    Web3.toTask
        { method = "eth.estimateGas"
        , params = Encode.list [ encodeTxParams txParams ]
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


{-| web3.eth.net methods
-}
getId : Task Error Int
getId =
    Web3.toTask
        { method = "eth.net.getId"
        , params = Encode.list []
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


isListening : Task Error Bool
isListening =
    Web3.toTask
        { method = "eth.net.isListening"
        , params = Encode.list []
        , expect = expectBool
        , callType = Async
        , applyScope = Nothing
        }


getPeerCount : Task Error Int
getPeerCount =
    Web3.toTask
        { method = "eth.net.getPeerCount"
        , params = Encode.list []
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getNetworkType : Task Error Network
getNetworkType =
    Web3.toTask
        { method = "eth.net.getNetworkType"
        , params = Encode.list []
        , expect = expectJson networkTypeDecoder
        , callType = Async
        , applyScope = Nothing
        }


{-| Default Parameter Helpers
-}
defaultTxParams : TxParams
defaultTxParams =
    { from = Nothing
    , to = Nothing
    , value = Nothing
    , data = Nothing
    , gas = Nothing
    , gasPrice = Just 8000000000
    , nonce = Nothing
    }


defaultFilterParams : FilterParams
defaultFilterParams =
    { fromBlock = Nothing
    , toBlock = Nothing
    , address = Nothing
    , topics = Nothing
    }
