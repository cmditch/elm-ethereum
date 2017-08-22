module Web3.Eth
    exposing
        ( setDefaultAccount
        , getDefaultAccount
        , getSyncing
        , coinbase
        , getHashrate
        , getGasPrice
        , getAccounts
        , getMining
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
        , defaultTxParams
        , defaultFilterParams
        )

{-| Web3.Eth
-}

import Web3
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (encodeTxParams, getBlockIdValue)
import Web3.EM
import Json.Encode as Encode
import Json.Decode as Decode
import Task exposing (Task)
import BigInt exposing (BigInt)


setDefaultAccount : Address -> Task Error Address
setDefaultAccount (Address address) =
    Web3.setOrGet
        { func = "eth.defaultAccount"
        , args = Encode.list [ Encode.string address ]
        , expect = expectJson addressDecoder
        , callType = Setter
        }


getDefaultAccount : Task Error Address
getDefaultAccount =
    Web3.setOrGet
        { func = "eth.defaultAccount"
        , args = Encode.list []
        , expect = expectJson addressDecoder
        , callType = Getter
        }


getSyncing : Task Error (Maybe SyncStatus)
getSyncing =
    Web3.toTask
        { func = "eth.getSyncing"
        , args = Encode.list []
        , expect = expectJson (Decode.maybe syncStatusDecoder)
        , callType = Async
        }


watchMinedBlocks : String -> Cmd msg
watchMinedBlocks name =
    Web3.EM.watchFilter name "latest"


watchIncomingTxs : String -> Cmd msg
watchIncomingTxs name =
    Web3.EM.watchFilter name "pending"



{-
   Implement within Effect Manager.
   NOTE Doesn't seem to work within MetaMask!
   isSyncing : Task Error (Maybe SyncStatus)

-}


getCoinbase : Task Error Address
getCoinbase =
    Web3.toTask
        { func = "eth.getCoinbase"
        , args = Encode.list []
        , expect = expectJson addressDecoder
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
        , expect = expectJson (Decode.list addressDecoder)
        , callType = Async
        }


accounts : Task Error (List Address)
accounts =
    getAccounts


getBlockNumber : Task Error BlockId
getBlockNumber =
    Web3.toTask
        { func = "eth.getBlockNumber"
        , args = Encode.list []
        , expect = expectJson blockNumDecoder
        , callType = Async
        }


getBalance : Address -> Task Error BigInt
getBalance (Address address) =
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
getStorageAtBlock blockId (Address address) position =
    Web3.toTask
        { func = "eth.getStorageAt"
        , args = Encode.list [ Encode.string address, Encode.int position, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
        , callType = Async
        }


getCode : Address -> Task Error Bytes
getCode =
    getCodeAtBlock Latest


getCodeAtBlock : BlockId -> Address -> Task Error Bytes
getCodeAtBlock blockId (Address address) =
    Web3.toTask
        { func = "eth.getStorageAt"
        , args = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectJson bytesDecoder
        , callType = Async
        }


getBlock : BlockId -> Task Error (Block TxId)
getBlock blockId =
    Web3.toTask
        { func = "eth.getBlock"
        , args = Encode.list [ getBlockIdValue blockId, Encode.bool False ]
        , expect = expectJson blockTxIdDecoder
        , callType = Async
        }


getBlockTxObjs : BlockId -> Task Error (Block TxObj)
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


getBlockUncleCount : BlockId -> Task Error Int
getBlockUncleCount blockId =
    Web3.toTask
        { func = "eth.getBlockUncleCount"
        , args = Encode.list [ getBlockIdValue blockId ]
        , expect = expectInt
        , callType = Async
        }


getUncle : BlockId -> Int -> Task Error (Maybe (Block TxId))
getUncle blockId index =
    Web3.toTask
        { func = "eth.getUncle"
        , args = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool False ]
        , expect = expectJson (Decode.maybe blockTxIdDecoder)
        , callType = Async
        }


getUncleTxObjs : BlockId -> Int -> Task Error (Block TxObj)
getUncleTxObjs blockId index =
    Web3.toTask
        { func = "eth.getUncle"
        , args = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool True ]
        , expect = expectJson blockTxObjDecoder
        , callType = Async
        }


getTransaction : TxId -> Task Error TxObj
getTransaction (TxId txId) =
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
getTransactionReceipt (TxId txId) =
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
getTransactionCountAtBlock blockId (Address address) =
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
        , args = Encode.list [ encodeTxParams txParams ]
        , expect = expectJson txIdDecoder
        , callType = Async
        }


sendRawTransaction : Bytes -> Task Error TxId
sendRawTransaction (Bytes signedData) =
    Web3.toTask
        { func = "eth.sendRawTransaction"
        , args = Encode.list [ Encode.string signedData ]
        , expect = expectJson txIdDecoder
        , callType = Async
        }


sign : Address -> Bytes -> Task Error Bytes
sign (Address address) (Bytes bytes) =
    Web3.toTask
        { func = "eth.sign"
        , args = Encode.list [ Encode.string address, Encode.string bytes ]
        , expect = expectJson bytesDecoder
        , callType = Async
        }


call : TxParams -> Task Error TxId
call =
    callAtBlock Latest


callAtBlock : BlockId -> TxParams -> Task Error TxId
callAtBlock blockId txParams =
    Web3.toTask
        { func = "eth.call"
        , args = Encode.list [ encodeTxParams txParams, getBlockIdValue blockId ]
        , expect = expectJson txIdDecoder
        , callType = Async
        }


estimateGas : TxParams -> Task Error Int
estimateGas txParams =
    Web3.toTask
        { func = "eth.estimateGas"
        , args = Encode.list [ encodeTxParams txParams ]
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
