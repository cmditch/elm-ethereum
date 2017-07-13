module Web3.Eth exposing (..)
{-
    Turn off elm-format when editing this file!!!
-}

type alias Address = Hex20
type alias TxHash = Hex32
type alias Wei = BigInt


type alias Block =
    { number : Int
    , hash : BlockHash
    , parentHash : Hex32
    , nonce : Hex8
    , sha3Uncles : Hex32
    , logsBloom : Hex256
    , transactionsRoot : Hex32
    , stateRoot : Hex32
    , miner : Address
    , difficulty : BigInt
    , totalDifficulty : BigInt
    , extraData : Hex
    , size : Int
    , gasLimit : Int
    , gasUsed : Int
    , timestamp : Int
    , transactions : List TxHash -- or TxObjects depending on arguements
    , uncles : List Hex32
    }


-- To send or call tx's
type TxData =
    { from : Address -- default is defaultAccount, optional when using web3.eth.call
    , to : Address -- optional, except on web3.eth.call()
    , value : Wei -- optional
    , gas : Wei -- default is To-Be-Determined
    , gasPrice : Wei -- default is To-Be-Determined
    , data : Hex -- optional, except on web3.eth.call()
    , none : Int -- optional
    }


-- Mined or Unmined txInfo
type TxInfo =
    { hash : TxHash
    , nonce : Int
    , blockHash : BlockHash || Null -- if pending block
    , blockNumber : BlockNumber || Null -- if pending block
    , transactionIndex : Int || Null -- if pending block
    , from : Address
    , to : Address || Null -- if contract creation tx
    , value : Wei
    , gasPrice : Wei
    , gas : Int
    , input : Hex
    }


-- Mined TxInfo
type alias TxReceipt =
    { blockHash : BlockHash
    , blockNumber : BlockNumber
    , transactionHash : String
    , transactionIndex : Int
    , from : Address
    , to : Address || Null -- if contract creation tx
    , cumulativeGasUsed : Int
    , gasUsed : Int
    , contractAddress : String || Null -- if not a contract
    , logs : List Log
    , logsBloom : Hex256
    }


type BlockId
    = Latest -- Latest block, current blockchain head
    | Earliest -- Genesis Block
    | Pending -- Block being mined
    | BlockNumber Int -- Block at specific number
    | BlockHash Hex32 -- Hash of Block

-- Address Functions
defaultAccount : Address
getCoinbase : Address
getAccounts : List Address
getBalance : Address -> Wei
getStorageAt : Address -> Hex


-- Block Functions
defaultBlock : BlockId -- Function is setter and getter in web3
getBlockNumber : BlockNumber
getBlock : BlockId -> Block
getBlockTransactionCount : BlockId -> Int
getUncle : BlockId -> Int -> Block -- 2nd param is Uncle Index
getGasPrice : Wei


-- Transaction Functions
getTransaction : TxHash -> TxInfo
getTransactionFromBlock : BlockId -> Int -> TxInfo -- Int is transactionIndex
getTransactionReceipt : TxHash -> TxReceipt -- Only available for mined transactions
getTransactionCount : TxHash -> BlockId -> Int -- BlockId is latest block by default
sendTransaction : TxData -> TxHash
sendRawTransaction : Hex -> TxHash
call : TxData -> Hex


-- Helper Functions
sign : Address -> Hex32 -> Hex65


-- Node related functions
type SyncStatus
    = NotSyncing
    | Syncing { startingBlock : Int
              , currentBlock : Int
              , highestBlock : Int
              }

getSyncing : SyncStatus
