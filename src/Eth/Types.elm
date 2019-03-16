module Eth.Types exposing
    ( Address, TxHash, BlockHash, Hex
    , Call, Send, Tx, TxReceipt, BlockId(..), Block, Uncle, BlockHead, Log, Event, LogFilter, SyncStatus
    , HttpProvider, WebsocketProvider, FilterId
    )

{-| Types


# Simple

@docs Address, TxHash, BlockHash, Hex


# Complex

@docs Call, Send, Tx, TxReceipt, BlockId, Block, Uncle, BlockHead, Log, Event, LogFilter, SyncStatus


# Misc

@docs HttpProvider, WebsocketProvider, FilterId

-}

import BigInt exposing (BigInt)
import Http
import Internal.Types as Internal
import Json.Decode exposing (Decoder)
import Time exposing (Posix)


type Error
    = Http Http.Error -- Standard HTTP Errors
    | Encoding String -- Most likely an overflow of int/uint
      -- Call returns 0x, could mean:
      -- Contract doesn't exist
      -- Contract function doesn't exist
      -- Other things (look at the talk by Augur team at Devcon4 on mainstage)
    | ZeroX String
      -- TxSentry Errors:
    | UserRejected -- User dissapproved of tx in Wallet
    | Web3Undefined -- Web3 object, or provider not found.



-- Simple


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
type alias Hex =
    Internal.Hex



-- Complex


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
    = BlockNum Int
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
    , timestamp : Posix
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
    , timestamp : Posix
    }


{-| -}
type alias Log =
    { address : Address
    , data : String
    , topics : List Hex
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
    , topics : List Hex
    , removed : Bool
    , logIndex : Int
    , transactionIndex : Int
    , transactionHash : TxHash
    , blockHash : BlockHash
    , blockNumber : Int
    , returnData : a
    }


{-| NOTE: Different from JSON RPC API, removed some optionality to reduce complexity (array with array)
-}
type alias LogFilter =
    { fromBlock : BlockId
    , toBlock : BlockId
    , address : Address
    , topics : List (Maybe Hex)
    }


{-| -}
type alias SyncStatus =
    { startingBlock : Int
    , currentBlock : Int
    , highestBlock : Int
    , knownStates : Int
    , pulledStates : Int
    }



-- Misc


{-| -}
type alias HttpProvider =
    String


{-| -}
type alias WebsocketProvider =
    String


{-| -}
type alias FilterId =
    String
