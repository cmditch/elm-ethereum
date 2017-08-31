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


type ByteArray
    = ByteArray (List Int)


type Hex
    = Hex String


type Sha3
    = Sha3 String


type Abi
    = Abi String



{-
   BLOCKS
-}


type BlockId
    = BlockNum Int
    | BlockHash String
    | Latest
    | Earliest
    | Pending


type alias Block a =
    { author : Maybe Address
    , difficulty : BigInt
    , extraData : String
    , gasLimit : Int
    , gasUsed : Int
    , hash : BlockId
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


type alias BlockTxObjs =
    Block TxObj


type alias BlockTxIds =
    Block TxId



{-
   TRANSACTIONS
-}


type alias TxObj =
    { blockHash : BlockId
    , blockNumber : Int
    , creates : Maybe Address
    , from : Address
    , gas : Int
    , gasPrice : BigInt
    , hash : TxId
    , input : Bytes
    , networkId : Maybe Int
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
    { transactionHash : TxId
    , transactionIndex : Int
    , blockHash : BlockId
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


type alias FilterParams =
    { fromBlock : Maybe BlockId
    , toBlock : Maybe BlockId
    , address : Maybe (List Address)
    , topics : Maybe (List (Maybe String))
    }


type alias EventLog a =
    { address : Address
    , args : a
    , blockHash :
        Maybe String

    -- TODO Possible to make BlockId?
    , blockNumber : Maybe Int
    , event : String
    , logIndex : Maybe Int
    , transactionHash : TxId
    , transactionIndex : Int
    }


type alias Log =
    -- TODO Log { type_ } field is an elm keyword... remedy?
    { address : Address
    , blockHash : Maybe String
    , blockNumber : Maybe Int
    , data : String
    , logIndex : Maybe Int
    , topics : List String
    , transactionHash : TxId
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
    | Setter
    | Getter


{-| Available ethereum denominations.
-}
type EthUnit
    = Wei --        Base Unit
    | Kwei --       10 ^ 3
    | Ada --        10 ^ 3
    | Femtoether -- 10 ^ 3
    | Mwei --       10 ^ 6
    | Babbage --    10 ^ 6
    | Picoether --  10 ^ 6
    | Gwei --       10 ^ 9
    | Shannon --    10 ^ 9
    | Nanoether --  10 ^ 9
    | Nano --       10 ^ 9
    | Szabo --      10 ^ 12
    | Microether -- 10 ^ 12
    | Micro --      10 ^ 12
    | Finney --     10 ^ 15
    | Milliether -- 10 ^ 15
    | Milli --      10 ^ 15
    | Ether --      10 ^ 18
    | Kether --     10 ^ 21
    | Grand --      10 ^ 21
    | Einstein --   10 ^ 21
    | Mether --     10 ^ 24
    | Gether --     10 ^ 27
    | Tether --     10 ^ 30
