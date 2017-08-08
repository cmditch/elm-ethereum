module Web3.Types exposing (..)

import BigInt exposing (BigInt)


{-
   ERROR TYPES
-}


type Error
    = Error String
    | BadPayload String
    | NoWallet



{-
   ETHEREUM RUDIMENTS
-}


type Address
    = Address String


type TxId
    = TxId String


type Bytes
    = Bytes String


type Hex
    = Hex String


type Keccak256
    = Keccak256 String


type ChecksumAddress
    = ChecksumAddress String


type Abi
    = Abi String



{-
   BLOCKS
-}


type BlockId
    = BlockNum Int
    | BlockHash Hex
    | Latest
    | Earliest
    | Pending


type alias Block a =
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
    , transactions : List a
    , transactionsRoot : String
    , uncles : List String
    }



{-
   TRANSACTIONS
-}


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


type alias TxParams =
    { from : Maybe Address
    , to : Maybe Address
    , value : Maybe BigInt
    , gas : Maybe Int
    , data : Maybe Bytes
    , gasPrice : Maybe Int
    , nonce : Maybe Int
    }


type alias ContractInfo =
    { address : Address
    , txId : TxId
    }



{-
   EVENTS and FILTERS
-}


type alias EventParams argsFilter =
    { argsFilter : argsFilter
    , filterParams : FilterParams
    }


type alias FilterParams =
    { fromBlock : Maybe BlockId
    , toBlock : Maybe BlockId
    , address : Maybe (List Address)
    , topics : Maybe (List (Maybe String))
    }


type alias EventLog a =
    { address : String
    , args : a
    , blockHash : Maybe String
    , blockNumber : Maybe Int
    , event : String
    , logIndex : Maybe Int
    , transactionHash : String
    , transactionIndex : Int
    }


type alias Log =
    -- TODO Log { type_ } field is an elm keyword... remedy?
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



{-
   NODE
-}


type alias SyncStatus =
    { startingBlock : Int
    , currentBlock : Int
    , highestBlock : Int
    }



{-
   INTERNAL
-}


type Expect a
    = Expect


type CallType
    = Sync
    | Async
