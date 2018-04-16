module Web3.Types exposing (..)

import BigInt exposing (BigInt)
import Json.Decode exposing (Decoder)
import Time exposing (Time)
import Web3.Internal.Types as Internal


type alias Address =
    Internal.Address


type alias TxHash =
    Internal.TxHash


type alias HttpProvider =
    String


type alias Hex =
    Internal.Hex


type alias IPFSHash =
    Internal.IPFSHash


type alias BlockHash =
    Internal.BlockHash


type BlockId
    = BlockIdNum Int
    | BlockIdHash BlockHash
    | Earliest
    | Latest
    | Pending


type alias TxParams a =
    { to : Maybe Address
    , from : Maybe Address
    , gas : Maybe Int
    , gasPrice : Maybe BigInt
    , value : Maybe BigInt
    , data : Maybe Hex
    , nonce : Maybe Int
    , decoder : Decoder a
    }


type alias Send =
    { to : Maybe Address
    , from : Maybe Address
    , gas : Maybe Int
    , gasPrice : Maybe BigInt
    , value : Maybe BigInt
    , data : Maybe Hex
    , nonce : Maybe Int
    }


type alias Tx =
    { hash : TxHash
    , nonce : Int
    , blockHash : BlockHash
    , blockNumber : Int
    , transactionIndex : Int
    , from : Address
    , to : Maybe Address
    , value : BigInt
    , gasPrice : BigInt
    , gas : Int
    , input : String
    }


type alias PendingTx =
    { hash : TxHash
    , nonce : Int
    , from : Address
    , to : Maybe Address
    , value : BigInt
    , gasPrice : BigInt
    , gas : Int
    , input : String
    }


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
type alias Log =
    { address : Address
    , data : String
    , topics : List String
    , logIndex : Maybe String
    , transactionIndex : String
    , transactionHash : TxHash
    , blockHash : Maybe String
    , blockNumber : Maybe String
    }


type alias Event a =
    { address : Address
    , data : String
    , topics : List String
    , logIndex : Maybe String
    , transactionIndex : String
    , transactionHash : TxHash
    , blockHash : Maybe String
    , blockNumber : Maybe String
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


type NetworkId
    = Mainnet
    | Expanse
    | Ropsten
    | Rinkeby
    | RskMain
    | RskTest
    | Kovan
    | ETCMain
    | ETCTest
    | Private Int


type alias SyncStatus =
    { startingBlock : Int
    , currentBlock : Int
    , highestBlock : Int
    , knownStates : Int
    , pulledStates : Int
    }
