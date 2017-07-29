module Web3.Eth.Types exposing (..)

{-| Web3.Eth.Types
-}

import BigInt exposing (BigInt)
import Web3.Types exposing (Hex)
import Json.Encode exposing (Value)


type alias TxId =
    String


type alias Bytes =
    String


type alias Address =
    String


type alias ChecksumAddress =
    String


type alias Abi =
    String


type alias ContractInfo =
    { contractAddress : Address
    , transactionHash : TxId
    }


type alias ConstructorParams =
    Value


type alias TxParams =
    { from : Maybe Address
    , to : Maybe Address
    , value : Maybe BigInt
    , gas : Maybe Int
    , data : Maybe Bytes
    , gasPrice : Maybe Int
    , nonce : Maybe Int
    }


type alias CallData =
    { abi : Value
    , address : Address
    , args : Maybe Value
    }


type alias Block =
    { author : Address
    , difficulty : BigInt
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
    , totalDifficulty : BigInt
    , transactions : List String
    , transactionsRoot : String
    , uncles : List String
    }


type alias BlockTxObjs =
    { author : Address
    , difficulty : BigInt
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
    , totalDifficulty : BigInt
    , transactions : List TxObj
    , transactionsRoot : String
    , uncles : List String
    }


type alias TxObj =
    { blockHash : Hex
    , blockNumber : Int
    , creates : Maybe Address
    , from : Address
    , gas : Int
    , gasPrice : BigInt
    , hash : String
    , input : Bytes
    , networkId : Int
    , nonce : Int
    , publicKey : Hex
    , r : Hex
    , raw : Bytes
    , s : Hex
    , standardV : Hex
    , to : Maybe Address
    , logs : List Log
    , transactionIndex : Int
    , v : Hex
    , value : BigInt
    }


type alias TxReceipt =
    { transactionHash : String
    , transactionIndex : Int
    , blockHash : String
    , blockNumber : Int
    , gasUsed : Int
    , cumulativeGasUsed : Int
    , contractAddress : String
    , logs : List Log
    }



-- TODO Log { type_ } field is an elm keyword... remedy?


type alias FilterParams =
    { fromBlock : Maybe BlockId
    , toBlock : Maybe BlockId
    , address : Maybe Address
    , topics : Maybe (List (Maybe String))
    }


type alias Log =
    { address : String
    , blockHash : Maybe String
    , blockNumber : Maybe Int
    , data : String
    , logIndex : Maybe Int
    , topics : List String
    , transactionHash : String
    , transactionIndex : Int
    , transactionLogIndex : String
    , type_ : String
    }


type alias SyncStatus =
    { startingBlock : Int
    , currentBlock : Int
    , highestBlock : Int
    }


type BlockId
    = BlockNum Int
    | BlockHash Hex
    | Latest
    | Earliest
    | Pending
