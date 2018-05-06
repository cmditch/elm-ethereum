module Web3.Eth.Types
    exposing
        ( Address
        , TxHash
        , BlockHash
        , BlockId(..)
        , Call
        , Send
        , Tx
        , TxReceipt
        , Block
        , Uncle
        , BlockHead
        , Log
        , Event
        , LogFilter
        , SyncStatus
        )

{-| Types


# Simple

@docs Address, TxHash, BlockHash


# Complex

@docs Call, Send, Tx, TxReceipt, BlockId ,Block, Uncle, BlockHead, Log, Event, LogFilter, SyncStatus

-}

import BigInt exposing (BigInt)
import Json.Decode exposing (Decoder)
import Time exposing (Time)
import Web3.Internal.Types as Internal
import Web3.Types exposing (Hex)


{-| -}
type alias Address =
    Internal.Address


{-| -}
type alias TxHash =
    Internal.TxHash


{-| -}
type alias BlockHash =
    Internal.BlockHash


{-| -}
type alias Call a =
    { to : Maybe Address
    , from : Maybe Address
    , gas : Maybe Int
    , gasPrice : Maybe BigInt
    , value : Maybe BigInt
    , data : Maybe Hex
    , nonce : Maybe Int
    , decoder : Decoder a
    }


{-| -}
type alias Send =
    { to : Maybe Address
    , from : Maybe Address
    , gas : Maybe Int
    , gasPrice : Maybe BigInt
    , value : Maybe BigInt
    , data : Maybe Hex
    , nonce : Maybe Int
    }


{-| -}
type alias Tx =
    { hash : TxHash
    , nonce : Int
    , blockHash : Maybe BlockHash
    , blockNumber : Maybe Int
    , transactionIndex : Int
    , from : Address
    , to : Maybe Address
    , value : BigInt
    , gasPrice : BigInt
    , gas : Int
    , input : String
    }


{-| -}
type alias TxReceipt =
    { hash : TxHash
    , index : Int
    , blockHash : BlockHash
    , blockNumber : Int
    , gasUsed : BigInt
    , cumulativeGasUsed : BigInt
    , contractAddress : Maybe Address
    , logs : List Log
    , logsBloom : String
    , root : Maybe String
    , status : Maybe Bool
    }


{-| -}
type BlockId
    = BlockIdNum Int
    | BlockIdHash BlockHash
    | EarliestBlock
    | LatestBlock
    | PendingBlock


{-| -}
type alias Block a =
    { number : Int
    , hash : BlockHash
    , parentHash : BlockHash
    , nonce : String
    , sha3Uncles : String
    , logsBloom : String
    , transactionsRoot : String
    , stateRoot : String
    , receiptsRoot : String
    , miner : Address
    , difficulty : BigInt
    , totalDifficulty : BigInt
    , extraData : String
    , size : Int
    , gasLimit : Int
    , gasUsed : Int
    , timestamp : Time
    , transactions : List a
    , uncles : List String
    }


{-| -}
type alias Uncle =
    Block ()


{-| -}
type alias BlockHead =
    { number : Int
    , hash : BlockHash
    , parentHash : BlockHash
    , nonce : String
    , sha3Uncles : String
    , logsBloom : String
    , transactionsRoot : String
    , stateRoot : String
    , receiptsRoot : String
    , miner : Address
    , difficulty : BigInt
    , extraData : String
    , gasLimit : Int
    , gasUsed : Int
    , mixHash : String
    , timestamp : Time
    }


{-| -}
type alias Log =
    { address : Address
    , data : String
    , topics : List String
    , removed : Bool
    , logIndex : Int
    , transactionIndex : Int
    , transactionHash : TxHash
    , blockHash : BlockHash
    , blockNumber : Int
    }


{-| -}
type alias Event a =
    { address : Address
    , data : String
    , topics : List String
    , removed : Bool
    , logIndex : Int
    , transactionIndex : Int
    , transactionHash : TxHash
    , blockHash : BlockHash
    , blockNumber : Int
    , returnData : a
    }


{-| NOTE: Different from JSON RPC API, removed some optionality to reduce complexity
-}
type alias LogFilter =
    { fromBlock : BlockId
    , toBlock : BlockId
    , address : Address
    , topics : List (Maybe String)
    }


{-| -}
type alias SyncStatus =
    { startingBlock : Int
    , currentBlock : Int
    , highestBlock : Int
    , knownStates : Int
    , pulledStates : Int
    }
