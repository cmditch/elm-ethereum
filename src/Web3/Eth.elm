module Web3.Eth
    exposing
        ( setDefaultAccount
        , getDefaultAccount
        , getBlockNumber
        , getBlock
        , coinbase
        , estimateGas
        , sendTransaction
        , defaultTxParams
        , defaultFilterParams
        )

{-| Web3.Eth
-}

import Web3
import Web3.Types exposing (..)
import Web3.Decoders exposing (expectInt, expectBool, expectJson, expectString, expectBigInt)
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (encodeTxParams, getBlockIdValue)
import Web3.EM
import Json.Encode as Encode
import Json.Decode as Decode
import Task exposing (Task)
import BigInt exposing (BigInt)


setDefaultAccount : Address -> Task Error Address
setDefaultAccount (Address address) =
    Web3.setOrGet Setter
        { func = "eth.defaultAccount"
        , args = Encode.list [ Encode.string address ]
        , expect = expectJson addressDecoder
        }


getDefaultAccount : Task Error Address
getDefaultAccount =
    Web3.setOrGet Getter
        { func = "eth.defaultAccount"
        , args = Encode.list []
        , expect = expectJson addressDecoder
        }


getSyncing : Task Error (Maybe SyncStatus)
getSyncing =
    Web3.toTask
        { func = "eth.getSyncing"
        , args = Encode.list []
        , expect = expectJson (Decode.maybe syncStatusDecoder)
        }


watchMinedBlocks : String -> Cmd msg
watchMinedBlocks name =
    Web3.EM.watchFilter name "latest"


watchIncomingTxs : String -> Cmd msg
watchIncomingTxs name =
    Web3.EM.watchFilter name "pending"



-- Tricky one to implement, maybe ports only?
-- isSyncing : Task Error (Maybe SyncStatus)
-- isSyncing =
-- https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethissyncing


getCoinbase : Task Error Address
getCoinbase =
    Web3.toTask
        { func = "eth.getCoinbase"
        , args = Encode.list []
        , expect = expectJson addressDecoder
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
        }


getHashrate : Task Error Int
getHashrate =
    Web3.toTask
        { func = "eth.getHashrate"
        , args = Encode.list []
        , expect = expectInt
        }


getGasPrice : Task Error BigInt
getGasPrice =
    Web3.toTask
        { func = "eth.getGasPrice"
        , args = Encode.list []
        , expect = expectBigInt
        }


getAccounts : Task Error (List Address)
getAccounts =
    Web3.toTask
        { func = "eth.getAccounts"
        , args = Encode.list []
        , expect = expectJson (Decode.list addressDecoder)
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
        }


getBalance : Address -> Task Error BigInt
getBalance (Address address) =
    Web3.toTask
        { func = "eth.getBalance"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBigInt
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
        }


getBlock : BlockId -> Task Error (Block String)
getBlock blockId =
    Web3.toTask
        { func = "eth.getBlock"
        , args = Encode.list [ getBlockIdValue blockId, Encode.bool False ]
        , expect = expectJson blockDecoder
        }



-- TODO Change name of BlockTxObjs type?


getBlockTxObjs : BlockId -> Task Error (Block TxObj)
getBlockTxObjs blockId =
    Web3.toTask
        { func = "eth.getBlock"
        , args = Encode.list [ getBlockIdValue blockId, Encode.bool True ]
        , expect = expectJson blockTxObjDecoder
        }


getBlockTransactionCount : BlockId -> Task Error Int
getBlockTransactionCount blockId =
    Web3.toTask
        { func = "eth.getBlockTransactionCount"
        , args = Encode.list [ getBlockIdValue blockId ]
        , expect = expectInt
        }


getUncle : BlockId -> Int -> Task Error (Block String)
getUncle blockId index =
    Web3.toTask
        { func = "eth.getUncle"
        , args = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool False ]
        , expect = expectJson blockDecoder
        }


getUncleTxObjs : BlockId -> Int -> Task Error (Block TxObj)
getUncleTxObjs blockId index =
    Web3.toTask
        { func = "eth.getUncle"
        , args = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool True ]
        , expect = expectJson blockTxObjDecoder
        }


getTransaction : TxId -> Task Error TxObj
getTransaction (TxId txId) =
    Web3.toTask
        { func = "eth.getTransaction"
        , args = Encode.list [ Encode.string txId ]
        , expect = expectJson txObjDecoder
        }


getTransactionFromBlock : BlockId -> Int -> Task Error TxObj
getTransactionFromBlock blockId index =
    Web3.toTask
        { func = "eth.getTransactionFromBlock"
        , args = Encode.list [ getBlockIdValue blockId, Encode.int index ]
        , expect = expectJson txObjDecoder
        }


getTransactionReceipt : TxId -> Task Error TxReceipt
getTransactionReceipt (TxId txId) =
    Web3.toTask
        { func = "eth.getTransactionReceipt"
        , args = Encode.list [ Encode.string txId ]
        , expect = expectJson txReceiptDecoder
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
        }


sendTransaction : TxParams -> Task Error TxId
sendTransaction txParams =
    Web3.toTask
        { func = "eth.sendTransaction"
        , args = Encode.list [ encodeTxParams txParams ]
        , expect = expectJson txIdDecoder
        }


sendRawTransaction : Bytes -> Task Error TxId
sendRawTransaction (Bytes signedData) =
    Web3.toTask
        { func = "eth.sendRawTransaction"
        , args = Encode.list [ Encode.string signedData ]
        , expect = expectJson txIdDecoder
        }


sign : Address -> Bytes -> Task Error Bytes
sign (Address address) (Bytes bytes) =
    Web3.toTask
        { func = "eth.sign"
        , args = Encode.list [ Encode.string address, Encode.string bytes ]
        , expect = expectJson bytesDecoder
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
        }


estimateGas : TxParams -> Task Error Int
estimateGas txParams =
    Web3.toTask
        { func = "eth.estimateGas"
        , args = Encode.list [ encodeTxParams txParams ]
        , expect = expectInt
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
