module Web3.Types exposing (..)

import BigInt exposing (BigInt)


{-
   ERROR TYPES
-}


type Error
    = Error String



{-
   ETHEREUM RUDIMENTS
-}


type Address
    = Address String


type TxId
    = TxId String


type Bytes
    = Bytes (List Int)


type Hex
    = Hex String


type Abi
    = Abi String


type Sha3
    = Sha3 String



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
    { miner : Maybe Address
    , difficulty : BigInt
    , extraData : String
    , gasLimit : Int
    , gasUsed : Int
    , hash : BlockId
    , logsBloom : String
    , mixHash : String
    , nonce : String
    , number : Int
    , parentHash : String
    , receiptsRoot : String
    , sha3Uncles : String
    , size : Int
    , stateRoot : String
    , timestamp : Int
    , totalDifficulty : BigInt
    , transactions : List a
    , transactionsRoot : String
    , uncles : List String
    }


type alias BlockHeader =
    { miner : Maybe Address
    , difficulty : BigInt
    , extraData : String
    , gasLimit : Int
    , gasUsed : Int
    , hash : BlockId
    , logsBloom : String
    , mixHash : String
    , nonce : String
    , number : Int
    , parentHash : String
    , receiptsRoot : String
    , sha3Uncles : String
    , stateRoot : String
    , timestamp : Int
    , transactionsRoot : String
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
    , input : Hex
    , networkId : Maybe Int
    , nonce : Int
    , publicKey : Hex
    , r : Hex
    , raw : Hex
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
    , contractAddress : Maybe Address
    , logs : List Log
    }


type alias TxParams =
    { to : Maybe Address
    , value : Maybe BigInt
    , gas : Int
    , data : Maybe Hex
    , gasPrice : Maybe Int
    , chainId : Maybe Int
    , nonce : Maybe Int
    }


type alias SignedTx =
    { messageHash : Sha3
    , r : Hex
    , s : Hex
    , v : Hex
    , rawTransaction : Hex
    }


type alias SignedMsg =
    { message : Maybe String
    , messageHash : Sha3
    , r : Hex
    , s : Hex
    , v : Hex
    , signature : Hex
    }


type alias ContractInfo =
    { address : Address
    , txId : TxId
    }



{-
   SUBSCRIPTIONS
-}


type Subscription
    = PendingTxs
    | NewBlockHeaders
    | Syncing
    | Logs LogParams


type alias LogParams =
    { fromBlock : BlockId
    , toBlock : BlockId
    , address : List Address
    , topics : List (Maybe (List String))
    }


type alias EventLog a =
    { address : Address
    , blockHash : Maybe String -- Make BlockId?
    , blockNumber : Maybe Int
    , transactionHash : TxId
    , transactionIndex : Int
    , logIndex : Maybe Int
    , removed : Bool
    , id : String
    , returnValues : a
    , event : String
    , signature : Maybe Hex
    , raw : { data : Hex, topics : List Hex }
    }


type alias Log =
    { address : Address
    , data : String
    , topics : List String
    , logIndex : Maybe Int
    , transactionIndex : Int
    , transactionHash : TxId
    , blockHash : Maybe String
    , blockNumber : Maybe Int
    }



{-
   WALLET / ACCOUNTS
-}


type PrivateKey
    = PrivateKey String


type WalletIndex
    = AddressIndex Address
    | IntIndex Int


type alias Account =
    { address : Address
    , privateKey : PrivateKey
    }


type alias Keystore =
    { version : Int
    , id : String
    , address : String
    , crypto : Crypto
    }


type alias Crypto =
    { ciphertext : String
    , cipherparams : { iv : String }
    , cipher : String
    , kdf : String
    , kdfparams :
        { dklen : Int
        , salt : String
        , n : Int
        , r : Int
        , p : Int
        }
    , mac : String
    }



{-
   NODE
-}


type alias SyncStatus =
    { startingBlock : Int
    , currentBlock : Int
    , highestBlock : Int
    , knownStates : Int
    , pulledStates : Int
    }


type Network
    = MainNet
    | Morden
    | Ropsten
    | Kovan
    | Private



{-
   INTERNAL
-}


type EthUnit
    = Wei
    | Kwei
    | Ada
    | Femtoether
    | Mwei
    | Babbage
    | Picoether
    | Gwei
    | Shannon
    | Nanoether
    | Nano
    | Szabo
    | Microether
    | Micro
    | Finney
    | Milliether
    | Milli
    | Ether
    | Kether
    | Grand
    | Einstein
    | Mether
    | Gether
    | Tether
