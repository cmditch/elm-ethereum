module Web3.Eth.Types exposing (..)

{-| Web3.Eth.Types
-}

import Web3 exposing (Address)
import BigInt exposing (BigInt)


type alias TxId =
    String


type alias TxData =
    String


type alias TxParams =
    { from : Address
    , value : Maybe BigInt
    , gas : Maybe BigInt
    , data : Maybe TxData
    }


type alias Block =
    { author : String
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
