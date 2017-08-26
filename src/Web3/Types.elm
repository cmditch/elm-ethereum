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
    | BlockHash String
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
    = Wei --        1
    | Kwei --       1000
    | Ada --        1000
    | Femtoether -- 1000
    | Mwei --       1000000
    | Babbage --    1000000
    | Picoether --  1000000
    | Gwei --       1000000000
    | Shannon --    1000000000
    | Nanoether --  1000000000
    | Nano --       1000000000
    | Szabo --      1000000000000
    | Microether -- 1000000000000
    | Micro --      1000000000000
    | Finney --     1000000000000000
    | Milliether -- 1000000000000000
    | Milli --      1000000000000000
    | Ether --      1000000000000000000
    | Kether --     1000000000000000000000
    | Grand --      1000000000000000000000
    | Einstein --   1000000000000000000000
    | Mether --     1000000000000000000000000
    | Gether --     1000000000000000000000000000
    | Tether --     1000000000000000000000000000000
