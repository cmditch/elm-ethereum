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

import Web3.Internal as Internal exposing (CallType(..))
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Task exposing (Task)
import BigInt exposing (BigInt)


getProtocolVersion : Task Error String
getProtocolVersion =
    Internal.toTask
        { method = "eth.getProtocolVersion"
        , params = Encode.list []
        , expect = expectString
        , callType = Async
        , applyScope = Nothing
        }


isSyncing : Task Error (Maybe SyncStatus)
isSyncing =
    Internal.toTask
        { method = "eth.isSyncing"
        , params = Encode.list []
        , expect = expectJson syncStatusDecoder
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
    Internal.toTask
        { method = "eth.getCoinbase"
        , params = Encode.list []
        , expect = expectJson addressDecoder
        , callType = Async
        , applyScope = Nothing
        }


isMining : Task Error Bool
isMining =
    Internal.toTask
        { method = "eth.isMining"
        , params = Encode.list []
        , expect = expectBool
        , callType = Async
        , applyScope = Nothing
        }


getHashrate : Task Error Int
getHashrate =
    Internal.toTask
        { method = "eth.getHashrate"
        , params = Encode.list []
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getGasPrice : Task Error BigInt
getGasPrice =
    Internal.toTask
        { method = "eth.getGasPrice"
        , params = Encode.list []
        , expect = expectBigInt
        , callType = Async
        , applyScope = Nothing
        }


getAccounts : Task Error (List Address)
getAccounts =
    Internal.toTask
        { method = "eth.getAccounts"
        , params = Encode.list []
        , expect = expectJson (Decode.list addressDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getBlockNumber : Task Error BlockId
getBlockNumber =
    Internal.toTask
        { method = "eth.getBlockNumber"
        , params = Encode.list []
        , expect = expectJson blockNumDecoder
        , callType = Async
        , applyScope = Nothing
        }


getBalance : Address -> Task Error BigInt
getBalance (Address address) =
    Internal.toTask
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
    Internal.toTask
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
    Internal.toTask
        { method = "eth.getCode"
        , params = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


getBlockTransactionCount : BlockId -> Task Error (Maybe Int)
getBlockTransactionCount blockId =
    Internal.toTask
        { method = "eth.getBlockTransactionCount"
        , params = Encode.list [ getBlockIdValue blockId ]
        , expect = expectJson (Decode.maybe Decode.int)
        , callType = Async
        , applyScope = Nothing
        }


getBlock : BlockId -> Task Error (Maybe (Block TxId))
getBlock blockId =
    Internal.toTask
        { method = "eth.getBlock"
        , params = Encode.list [ getBlockIdValue blockId, Encode.bool False ]
        , expect = expectJson (Decode.maybe blockTxIdDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getBlockTxObjs : BlockId -> Task Error (Maybe (Block TxObj))
getBlockTxObjs blockId =
    Internal.toTask
        { method = "eth.getBlock"
        , params = Encode.list [ getBlockIdValue blockId, Encode.bool True ]
        , expect = expectJson (Decode.maybe blockTxObjDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getBlockUncleCount : BlockId -> Task Error (Maybe Int)
getBlockUncleCount blockId =
    Internal.toTask
        { method = "eth.getBlockUncleCount"
        , params = Encode.list [ getBlockIdValue blockId ]
        , expect = expectJson (Decode.maybe Decode.int)
        , callType = Async
        , applyScope = Nothing
        }


getUncle : BlockId -> Int -> Task Error (Maybe (Block TxId))
getUncle blockId index =
    Internal.toTask
        { method = "eth.getUncle"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool False ]
        , expect = expectJson (Decode.maybe blockTxIdDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getUncleTxObjs : BlockId -> Int -> Task Error (Maybe (Block TxObj))
getUncleTxObjs blockId index =
    Internal.toTask
        { method = "eth.getUncle"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool True ]
        , expect = expectJson (Decode.maybe blockTxObjDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getTransaction : TxId -> Task Error (Maybe TxObj)
getTransaction (TxId txId) =
    Internal.toTask
        { method = "eth.getTransaction"
        , params = Encode.list [ Encode.string txId ]
        , expect = expectJson (Decode.maybe txObjDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getTransactionFromBlock : BlockId -> Int -> Task Error (Maybe TxObj)
getTransactionFromBlock blockId index =
    Internal.toTask
        { method = "eth.getTransactionFromBlock"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index ]
        , expect = expectJson (Decode.maybe txObjDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getTransactionReceipt : TxId -> Task Error (Maybe TxReceipt)
getTransactionReceipt (TxId txId) =
    Internal.toTask
        { method = "eth.getTransactionReceipt"
        , params = Encode.list [ Encode.string txId ]
        , expect = expectJson (Decode.maybe txReceiptDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getTransactionCount : BlockId -> Address -> Task Error (Maybe Int)
getTransactionCount blockId (Address address) =
    Internal.toTask
        { method = "eth.getTransactionCount"
        , params = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectJson (Decode.maybe Decode.int)
        , callType = Async
        , applyScope = Nothing
        }


sendTransaction : Address -> TxParams -> Task Error TxId
sendTransaction from txParams =
    Internal.toTask
        { method = "eth.sendTransaction"
        , params = Encode.list [ encodeTxParams (Just from) txParams ]
        , expect = expectJson txIdDecoder
        , callType = Async
        , applyScope = Nothing
        }


sendSignedTransaction : Hex -> Task Error TxId
sendSignedTransaction (Hex signedData) =
    Internal.toTask
        { method = "eth.sendSignedTransaction"
        , params = Encode.list [ Encode.string signedData ]
        , expect = expectJson txIdDecoder
        , callType = Async
        , applyScope = Nothing
        }


sign : Address -> Hex -> Task Error Hex
sign (Address address) (Hex data) =
    Internal.toTask
        { method = "eth.sign"
        , params = Encode.list [ Encode.string data, Encode.string address ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


signTransaction : Address -> TxParams -> Task Error SignedTx
signTransaction address txParams =
    Internal.toTask
        { method = "eth.signTransaction"
        , params =
            Encode.list
                [ encodeTxParams (Just address) txParams
                , Encode.string (addressToString address)
                ]
        , expect = expectJson rpcSignedTxDecoder
        , callType = Async
        , applyScope = Nothing
        }


call : Maybe Address -> TxParams -> Task Error Hex
call =
    callAtBlock Latest


callAtBlock : BlockId -> Maybe Address -> TxParams -> Task Error Hex
callAtBlock blockId from txParams =
    -- TODO Look into removing 'from' field from TxParams since it's optional all over.
    Internal.toTask
        { method = "eth.call"
        , params = Encode.list [ encodeTxParams from txParams, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


estimateGas : TxParams -> Task Error Int
estimateGas txParams =
    Internal.toTask
        { method = "eth.estimateGas"
        , params = Encode.list [ encodeTxParams Nothing txParams ]
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getPastLogs : LogParams -> Task Error (List Log)
getPastLogs params =
    -- TODO Something wrong with this function in Web3
    Internal.toTask
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
    Internal.toTask
        { method = "eth.net.getId"
        , params = Encode.list []
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


isListening : Task Error Bool
isListening =
    Internal.toTask
        { method = "eth.net.isListening"
        , params = Encode.list []
        , expect = expectBool
        , callType = Async
        , applyScope = Nothing
        }


getPeerCount : Task Error Int
getPeerCount =
    Internal.toTask
        { method = "eth.net.getPeerCount"
        , params = Encode.list []
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getNetworkType : Task Error Network
getNetworkType =
    Internal.toTask
        { method = "eth.net.getNetworkType"
        , params = Encode.list []
        , expect = expectJson networkTypeDecoder
        , callType = Async
        , applyScope = Nothing
        }


currentProviderUrl : Task Error String
currentProviderUrl =
    Internal.toTask
        { method = "eth.currentProvider.connection.url"
        , params = Encode.list []
        , expect = expectString
        , callType = Getter
        , applyScope = Nothing
        }
