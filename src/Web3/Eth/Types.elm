module Web3.Eth.Types exposing (..)

{-| Web3.Eth.Types
-}

import BigInt exposing (BigInt)
import Json.Encode exposing (Value)


type TxId
    = TxId String


type TxData
    = TxData String


type Address
    = Address String


type Abi
    = Abi String


type alias TxParams =
    { from : Address
    , to : Maybe Address
    , value : Maybe BigInt
    , gas : Maybe Int
    , data : Maybe TxData
    , gasPrice : Maybe Int
    , nonce : Maybe Int
    }


type alias CallData =
    { abi : Value
    , address : Address
    , args : Maybe Value
    }


type alias SendData =
    { abi : Value
    , address : Address
    , params : TxParams
    , args : Maybe (List Value)
    , data : Maybe String
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
