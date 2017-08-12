module Main exposing (..)

-- MetaMask + MainNet (1)
---------------------


type alias Block =
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
    , transactionIndex :
        Int
        -- Different than MainNet_GetLog
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
    , transactionLogIndex :
        String
        -- Difference from MainNet_Log_inTxReceipt
    , type_ : String
    , event : String
    , args : SomethingArgs
    }



-- MetaMask + Ropsten (3)
---------------------


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


type alias Ropsten_TxObj =
    -- Contract was created on this
    { blockHash : String
    , blockNumber : Int
    , from : String
    , gas : Int
    , gasPrice : String
    , hash : String
    , input : String
    , nonce : Int
    , to : Maybe ComplexType
    , transactionIndex : Int
    , value : String
    , v : String
    , r : String
    , s : String
    }


type alias Ropsten_TxReceipt =
    { blockHash : String
    , blockNumber : Int
    , contractAddress : String
    , cumulativeGasUsed : Int
    , from : String
    , gasUsed : Int
    , logs : List ComplexType
    , logsBloom : String
    , root : String
    , to : String
    , transactionHash : String
    , transactionIndex : Int
    }


type alias Ropsten_Log =
    { address : String
    , topics : List String
    , data : String
    , blockNumber : Int
    , transactionHash : String
    , transactionIndex : Int
    , blockHash : String
    , logIndex : Int
    , removed : Bool
    }


type alias Ropsten_EventLog =
    { address : String
    , blockNumber : Int
    , transactionHash : String
    , transactionIndex : Int
    , blockHash : String
    , logIndex : Int
    , removed : Bool
    , event : String
    , args : SomethingArgs
    }



-- MetaMask + Kovan (3)
---------------------


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


type alias Kovan_TxReceipt =
    { blockHash : String
    , blockNumber : Int
    , contractAddress : Maybe ComplexType
    , cumulativeGasUsed : Int
    , gasUsed : Int
    , logs : List ComplexType
    , logsBloom : String
    , root : Maybe ComplexType
    , transactionHash : String
    , transactionIndex : Int
    }

type alias Kovan_Log =
    { address : String
    , blockHash : String
    , blockNumber : Int
    , data : String
    , logIndex : Int
    , topics : List String
    , transactionHash : String
    , transactionIndex : Int
    , transactionLogIndex : String
    , type : String
    }

    
