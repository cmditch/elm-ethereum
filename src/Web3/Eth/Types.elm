module Web3.Eth.Types exposing (..)

{-| Web3.Eth.Types
-}

import BigInt exposing (BigInt)
import Json.Encode exposing (Value)


type alias TxId =
    String


type alias Bytes =
    String


type alias Address =
    String


type alias Abi =
    String


type alias NewContract =
    { txId : TxId
    , address : Address
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


type alias Log =
    { address : String
    , blockHash : String
    , blockNumber : Int
    , data : String
    , logIndex : Int
    , topics : List String
    , transactionHash : String
    , transactionIndex : Int
    , transactionLogIndex : String
    , type_ : String
    }
