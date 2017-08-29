-- THESE ARE ALL OLD FROM web3.js 0.20.1
-- NEED TO CHECK THESE FOR web3.js 1.0


module Main exposing (..)

-- MetaMask + MainNet (1)
---------------------


type alias MainNet_Block =
    { author : String
    , difficulty : String
    , extraData : String
    , gasLimit : Int
    , gasUsed : Int
    , hash : String
    , logsBloom : String
    , miner : String
    , mixHash : String
    , nonce : String
    , number : Int
    , parentHash : String
    , receiptsRoot : String
    , sealFields : List String
    , sha3Uncles : String
    , size : Int
    , stateRoot : String
    , timestamp : Int
    , totalDifficulty : String
    , transactions : List String
    , transactionsRoot : String
    , uncles : List String
    }


type alias MainNet_TxObj =
    { blockHash : String
    , blockNumber : Int
    , condition : Maybe Unknown
    , creates : Maybe Unknown
    , from : String
    , gas : Int
    , gasPrice : String
    , hash : String
    , input : String
    , networkId : Int
    , nonce : Int
    , publicKey : String
    , r : String
    , raw : String
    , s : String
    , standardV : String
    , to : String
    , transactionIndex : Int
    , v : String
    , value : String
    }


type alias MainNet_TxReceipt =
    { blockHash : String
    , blockNumber : Int
    , contractAddress : Maybe String
    , cumulativeGasUsed : Int
    , from : String
    , gasUsed : Int
    , logs : List MainNet_Log_inTxReceipt
    , logsBloom : String
    , root : String
    , to : String
    , transactionHash : String
    , transactionIndex : Int
    }


type alias MainNet_Log =
    { address : String
    , blockHash : String
    , blockNumber : Int
    , logIndex : Int
    , transactionHash : String
    , transactionIndex : Int
    , topics : List String
    , data : String
    , removed : Bool
    }


type alias MainNet_EventLog =
    { address : String
    , blockHash : String
    , blockNumber : Int
    , logIndex : Int
    , transactionHash : String
    , transactionIndex : Int
    , transactionLogIndex : String
    , type_ : String
    , event : String
    , args : SomethingArgs
    }



-- MetaMask + Ropsten (3)
---------------------
{- MainNet Diff
   - author
   - sealFields
-}


type alias Ropsten_Block =
    { difficulty : String
    , extraData : String
    , gasLimit : Int
    , gasUsed : Int
    , hash : String
    , logsBloom : String
    , miner : String
    , mixHash : String
    , nonce : String
    , number : Int
    , parentHash : String
    , receiptsRoot : String
    , sha3Uncles : String
    , size : Int
    , stateRoot : String
    , timestamp : Int
    , totalDifficulty : String
    , transactions : List String
    , transactionsRoot : String
    , uncles : List String
    }



{- MainNet Diff
   - condition
   - creates
   - networkId
   - publicKey
   - raw
   - standardV
-}


type alias Ropsten_TxObj =
    { blockHash : String
    , blockNumber : Int
    , from : String
    , gas : Int
    , gasPrice : String
    , hash : String
    , input : String
    , nonce : Int
    , r : String
    , s : String
    , to : Maybe String
    , transactionIndex : Int
    , v : String
    , value : String
    }



-- No Diff from MainNet


type alias Ropsten_TxReceipt =
    { blockHash : String
    , blockNumber : Int
    , contractAddress : String
    , cumulativeGasUsed : Int
    , from : String
    , gasUsed : Int
    , logs : List Ropsten_Log
    , logsBloom : String
    , root : String
    , to : String
    , transactionHash : String
    , transactionIndex : Int
    }



-- No Diff from MainNet


type alias Ropsten_Log =
    { address : String
    , blockHash : String
    , blockNumber : Int
    , logIndex : Int
    , transactionHash : String
    , transactionIndex : Int
    , topics : List String
    , data : String
    , removed : Bool
    }



{- MainNet Diff
   - transactionLogIndex
   - type_
   + removed
-}


type alias Ropsten_EventLog =
    { address : String
    , blockHash : String
    , blockNumber : Int
    , logIndex : Int
    , transactionHash : String
    , transactionIndex : Int
    , removed : Bool
    , event : String
    , args : SomethingArgs
    }



-- MetaMask + Kovan (??)
---------------------
{- MainNet Diff
   - mixHash
   - nonce
   + signature
   + step
-}


type alias Kovan_Block =
    { author : String
    , difficulty : String
    , extraData : String
    , gasLimit : Int
    , gasUsed : Int
    , hash : String
    , logsBloom : String
    , miner : String
    , number : Int
    , parentHash : String
    , receiptsRoot : String
    , sealFields : List String
    , sha3Uncles : String
    , signature : String
    , size : Int
    , stateRoot : String
    , step : String
    , timestamp : Int
    , totalDifficulty : String
    , transactions : List ComplexType
    , transactionsRoot : String
    , uncles : List ComplexType
    }



-- No Diff from MainNet


type alias Kovan_TxObj =
    { blockHash : String
    , blockNumber : Int
    , condition : Maybe ComplexType
    , creates : Maybe ComplexType
    , from : String
    , gas : Int
    , gasPrice : String
    , hash : String
    , input : String
    , networkId : Maybe ComplexType
    , nonce : Int
    , publicKey : String
    , r : String
    , raw : String
    , s : String
    , standardV : String
    , to : String
    , transactionIndex : Int
    , v : String
    , value : String
    }



{- MainNet Diff
   - from
   - to
-}


type alias Kovan_TxReceipt =
    { blockHash : String
    , blockNumber : Int
    , contractAddress : Maybe String
    , cumulativeGasUsed : Int
    , gasUsed : Int
    , logs : List Kovan_Log
    , logsBloom : String
    , root : Maybe String
    , transactionHash : String
    , transactionIndex : Int
    }



{- MainNet Diff
   RECHECK THIS
-}


type alias Kovan_Log =
    { address : String
    , blockHash : String
    , blockNumber : Int
    , logIndex : Int
    , topics : List String
    , transactionHash : String
    , transactionIndex : Int
    , transactionLogIndex : String
    , data : String
    , type_ : String
    }


type alias Kovan_EventLog =
    Nothing



-- MetaMask + TestRPC (N)
---------------------
{- MainNet Diff
   - author
   - mixHash
   - sealFields
-}


type alias TestRPC_Block =
    { difficulty : String
    , extraData : String
    , gasLimit : Int
    , gasUsed : Int
    , hash : String
    , logsBloom : String
    , miner : String
    , nonce : String
    , number : Int
    , parentHash : String
    , receiptRoot : String
    , sha3Uncles : String
    , size : Int
    , stateRoot : String
    , timestamp : Int
    , totalDifficulty : String
    , transactions : List String
    , transactionsRoot : String
    , uncles : List String
    }



{- MainNet Diff
   - condition
   - creates
   - sealFields
   - networkId
   - publicKey
   - r
   - raw
   - s
   - standardV
   - v
-}


type alias TestRPC_TxObj =
    { blockHash : String
    , blockNumber : Int
    , from : String
    , gas : Int
    , gasPrice : String
    , input : String
    , hash : String
    , nonce : Int
    , to : Maybe String
    , transactionIndex : Int
    , value : String
    }



{- MainNet Diff
   - from
   - logsBloom
   - root
   - to
-}


type alias TestRPC_TxReceipt =
    { blockHash : String
    , blockNumber : Int
    , contractAddress : Maybe String
    , cumulativeGasUsed : Int
    , gasUsed : Int
    , logs : List TestRPC_Log
    , transactionHash : String
    , transactionIndex : Int
    }



{- MainNet Diff
   - removed
-}


type alias TestRPC_Log =
    { address : String
    , blockHash : String
    , blockNumber : Int
    , logIndex : Int
    , transactionHash : String
    , transactionIndex : Int
    , topics : List String
    , data : String
    , type_ : String
    }



{- MainNet Diff
   - transactionLogIndex
-}


type alias TestRPC_EventLog =
    { address : String
    , blockHash : String
    , blockNumber : Int
    , logIndex : Int
    , transactionHash : String
    , transactionIndex : Int
    , type_ : String
    , event : String
    , args : List Maybe
    }
