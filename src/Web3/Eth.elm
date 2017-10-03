module Web3.Eth
    exposing
        ( getProtocolVersion
        , isSyncing
        , getCoinbase
        , isMining
        , getHashrate
        , getGasPrice
        , getAccounts
        , getBlockNumber
        , getBalance
        , getStorageAt
        , getStorageAtBlock
        , getCode
        , getCodeAtBlock
        , getBlockTransactionCount
        , getBlock
        , getBlockTxObjs
        , getBlockUncleCount
        , getUncle
        , getUncleTxObjs
        , getTransaction
        , getTransactionFromBlock
        , getTransactionReceipt
        , getTransactionCount
        , sendTransaction
        , sendSignedTransaction
        , sign
        , signTransaction
        , call
        , callAtBlock
        , estimateGas
        , getPastLogs
        , getId
        , isListening
        , getPeerCount
        , getNetworkType
        , currentProviderUrl
        )

{-| Web3.Eth
-}

import Web3
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Task exposing (Task)
import BigInt exposing (BigInt)


getProtocolVersion : Task Error String
getProtocolVersion =
    Web3.toTask
        { method = "eth.getProtocolVersion"
        , params = Encode.list []
        , expect = expectString
        , callType = Async
        , applyScope = Nothing
        }


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
   isSyncing : Task Error (Maybe SyncStatus)
   Implement within Effect Manager.
   NOTE Doesn't seem to work within MetaMask!
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
    getCodeAtBlock Latest


getCodeAtBlock : BlockId -> Address -> Task Error Hex
getCodeAtBlock blockId (Address address) =
    Web3.toTask
        { method = "eth.getStorageAt"
        , params = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


getBlockTransactionCount : BlockId -> Task Error Int
getBlockTransactionCount blockId =
    Web3.toTask
        { method = "eth.getBlockTransactionCount"
        , params = Encode.list [ getBlockIdValue blockId ]
        , expect = expectInt
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


getUncleTxObjs : BlockId -> Int -> Task Error (Maybe (Block TxObj))
getUncleTxObjs blockId index =
    Web3.toTask
        { method = "eth.getUncle"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool True ]
        , expect = expectJson (Decode.maybe blockTxObjDecoder)
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


getTransactionCount : BlockId -> Address -> Task Error Int
getTransactionCount blockId (Address address) =
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


sign : Address -> Hex -> Task Error Hex
sign (Address address) (Hex data) =
    Web3.toTask
        { method = "eth.sign"
        , params = Encode.list [ Encode.string address, Encode.string data ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


signTransaction : Address -> TxParams -> Task Error Hex
signTransaction (Address address) txParams =
    Web3.toTask
        { method = "eth.signTransaction"
        , params = Encode.list [ encodeTxParams txParams, Encode.string address ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


call : TxParams -> Task Error Hex
call =
    callAtBlock Latest


callAtBlock : BlockId -> TxParams -> Task Error Hex
callAtBlock blockId txParams =
    -- TODO Look into removing 'from' field from TxParams since it's optional all over.
    Web3.toTask
        { method = "eth.call"
        , params = Encode.list [ encodeTxParams txParams, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
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


getPastLogs : FilterParams -> Task Error (List Log)
getPastLogs params =
    Web3.toTask
        { method = "eth.getPastLogs"
        , params = Encode.list [ encodeFilterParams params ]
        , expect = expectJson (Decode.list logDecoder)
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


currentProviderUrl : Task Error String
currentProviderUrl =
    Web3.toTask
        { method = "eth.currentProvider.connection"
        , params = Encode.list []
        , expect = expectString
        , callType = Getter
        , applyScope = Nothing
        }
