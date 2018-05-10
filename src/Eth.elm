module Eth
    exposing
        ( call
        , callAtBlock
        , estimateGas
        , getStorageAt
        , getStorageAtBlock
        , getCode
        , getCodeAtBlock
        , getTx
        , getTxReceipt
        , getTxByBlockHashAndIndex
        , getTxByBlockNumberAndIndex
        , toSend
        , encodeSend
        , sendTx
        , sendRawTx
        , getBalance
        , getBalanceAtBlock
        , getTxCount
        , getTxCountAtBlock
        , getBlockNumber
        , getBlock
        , getBlockByHash
        , getBlockWithTxObjs
        , getBlockByHashWithTxObjs
        , getBlockTxCount
        , getBlockTxCountByHash
        , getUncleCount
        , getUncleCountByHash
        , getUncleAtIndex
        , getUncleByBlockHashAtIndex
        , getLogs
        , newFilter
        , newBlockFilter
        , newPendingTxFilter
        , getFilterChanges
        , getFilterLogs
        , uninstallFilter
        , sign
        , protocolVersion
        , syncing
        , coinbase
        , mining
        , hashrate
        , gasPrice
        , accounts
        )

{-| Ethereum RPC Methods

See the [official docs][rpc-docs] for reference.

[rpc-docs]: [https://github.com/ethereum/wiki/wiki/JSON-RPC]


# Contracts

If you're making Eth transactions, you'll need to build a `Call`,
and send to a wallet like MetaMask via `Eth.Sentry.Tx`.

    ( newSentry, sentryCmd ) =
        myCallParams
            |> Eth.toSend
            |> TxSentry.send TxSendResponse model.txSentry

But most likely you're interacting with a contract,
what most dApps are typically engaged in. Use [elm-ethereum-generator](https://github.com/cmditch/elm-ethereum-generator)
to auto-generate the necessary `Elm <-> Contract` interface from a contract's ABI.

    import Eth
    import Eth.Types exposing (..)
    import Eth.Unit exposing (eth)
    import Evm.Decode as Evm
    import Evm.Encode as Evm exposing (Encoding(..))

    myCallParams : Call BigInt
    myCallParams =
        let
            data =
                Evm.encodeFunctionCall
                    "petKitten(uint256)"
                    [ UintE someBigInt ]
        in
            { to = Just cryptoKittyContract
            , from = Nothing
            , gas = Nothing
            , gasPrice = Nothing
            , value = Just (eth 3)
            , data = Just data
            , nonce = Nothing
            , decoder = Evm.toElmDecoder Evm.bool
            }


    type Msg
        = PetKitten
        | KittenResponse (Result Http.Error Bool)


    update msg model =
        case msg of
            PetKitten ->
                ( model
                , Eth.call model.nodeUrl myCallParams
                    |> Task.attempt KittenResponse
                )

            KittenResponse result ->
                case result of
                    ...

@docs call, estimateGas, getStorageAt, getCode, callAtBlock, getStorageAtBlock, getCodeAtBlock


# Transactions

@docs getTx, getTxReceipt, toSend, encodeSend, sendTx, sendRawTx, getTxByBlockHashAndIndex, getTxByBlockNumberAndIndex


# Address/Accounts

@docs getBalance, getBalanceAtBlock, getTxCount, getTxCountAtBlock


# Blocks

@docs getBlockNumber, getBlock, getBlockByHash, getBlockWithTxObjs, getBlockByHashWithTxObjs, getBlockTxCount, getBlockTxCountByHash, getUncleCount, getUncleCountByHash, getUncleAtIndex, getUncleByBlockHashAtIndex


# Filter/Logs/Events

@docs getLogs, newFilter, newBlockFilter, newPendingTxFilter, getFilterChanges, getFilterLogs, uninstallFilter


# Misc

@docs sign, protocolVersion, syncing, coinbase, mining, hashrate, gasPrice, accounts

-}

import BigInt exposing (BigInt)
import Eth.Types exposing (..)
import Eth.Decode as Decode
import Eth.RPC as RPC
import Http
import Internal.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Task exposing (Task)


-- Contracts


{-| Call a function on an Ethereum contract.
Useful for reading data from contracts, or simulating a transaction before doing a Send.

Use the elm-web3-contract code generator to produce an interface for a smart contract from it's ABI.

Note: The decoder for a call is baked into the Call record for a simpler developer experience.

-}
call : HttpProvider -> Call a -> Task Http.Error a
call ethNode txParams =
    callAtBlock ethNode txParams LatestBlock


{-| Call a function on an Ethereum contract from a particular point in history.
Adding some more documentation.
-}
callAtBlock : HttpProvider -> Call a -> BlockId -> Task Http.Error a
callAtBlock ethNode txParams blockId =
    RPC.toTask
        { url = ethNode
        , method = "eth_call"
        , params = [ Encode.txCall txParams, Encode.blockId blockId ]
        , decoder = txParams.decoder
        }


{-| Generates and returns an estimate of how much gas is necessary to allow the transaction to complete.

Note that the estimate may be significantly more than the amount of gas actually used by the transaction,
for a variety of reasons including EVM mechanics and node performance.

-}
estimateGas : HttpProvider -> Call a -> Task Http.Error Int
estimateGas ethNode txParams =
    RPC.toTask
        { url = ethNode
        , method = "eth_estimateGas"
        , params = [ Encode.txCall txParams ]
        , decoder = Decode.hexInt
        }


{-| Returns the value from a storage position at a given address.
See Ethereum JSON-RPC methods for specification on retrieving data from complex data structures like maps.
-}
getStorageAt : HttpProvider -> Address -> Int -> Task Http.Error String
getStorageAt ethNode address index =
    getStorageAtBlock ethNode address index LatestBlock


{-| Returns the value from a storage position at a given address, at a certain block height.
-}
getStorageAtBlock : HttpProvider -> Address -> Int -> BlockId -> Task Http.Error String
getStorageAtBlock ethNode address index blockId =
    RPC.toTask
        { url = ethNode
        , method = "eth_getStorageAt"
        , params = [ Encode.address address, Encode.hexInt index, Encode.blockId blockId ]
        , decoder = Decode.string
        }


{-| Returns the bytecode from a contract at a given address.
-}
getCode : HttpProvider -> Address -> Task Http.Error String
getCode ethNode address =
    getCodeAtBlock ethNode address LatestBlock


{-| Returns the bytecode from a contract at a given address, at a certain block height.
-}
getCodeAtBlock : HttpProvider -> Address -> BlockId -> Task Http.Error String
getCodeAtBlock ethNode address blockId =
    RPC.toTask
        { url = ethNode
        , method = "eth_getCode"
        , params = [ Encode.address address, Encode.blockId blockId ]
        , decoder = Decode.string
        }



-- Transactions


{-| Prepare a Call to be executed on chain.
Used in `Eth.Sentry.Tx`, a means to interact with MetaMask.
-}
toSend : Call a -> Send
toSend { to, from, gas, gasPrice, value, data, nonce } =
    { to = to
    , from = from
    , gas = gas
    , gasPrice = gasPrice
    , value = value
    , data = data
    , nonce = nonce
    }


{-| -}
encodeSend : Send -> Value
encodeSend { to, from, gas, gasPrice, value, data, nonce } =
    Encode.listOfMaybesToVal
        [ ( "to", Maybe.map Encode.address to )
        , ( "from", Maybe.map Encode.address from )
        , ( "gas", Maybe.map Encode.hexInt gas )
        , ( "gasPrice", Maybe.map Encode.bigInt gasPrice )
        , ( "value", Maybe.map Encode.bigInt value )
        , ( "data", Maybe.map Encode.hex data )
        , ( "nonce", Maybe.map Encode.hexInt nonce )
        ]


{-| Get transaction information from it's hash.
Includes pre-execution info: value, nonce, data/input, gas, gasPrice, to, and from.
-}
getTx : HttpProvider -> TxHash -> Task Http.Error Tx
getTx ethNode txHash =
    RPC.toTask
        { url = ethNode
        , method = "eth_getTransactionByHash"
        , params = [ Encode.txHash txHash ]
        , decoder = Decode.tx
        }


{-| Get the receipt of a transaction from it's hash.
Only exists after the transaction has been mined.

Includes post-execution info: gasUsed, cumulativeGasUsed, contractAddress, logs, logsBloom.
Also includes the tx execution status (if block is post-byzantium).

-}
getTxReceipt : HttpProvider -> TxHash -> Task Http.Error TxReceipt
getTxReceipt ethNode txHash =
    RPC.toTask
        { url = ethNode
        , method = "eth_getTransactionReceipt"
        , params = [ Encode.txHash txHash ]
        , decoder = Decode.txReceipt
        }


{-| Get a transaction by it's index in a certain block given the block hash.
-}
getTxByBlockHashAndIndex : HttpProvider -> BlockHash -> Int -> Task Http.Error Tx
getTxByBlockHashAndIndex ethNode blockHash txIndex =
    RPC.toTask
        { url = ethNode
        , method = "eth_getTransactionByBlockHashAndIndex"
        , params = [ Encode.blockHash blockHash, Encode.hexInt txIndex ]
        , decoder = Decode.tx
        }


{-| Get a transaction by it's index in a certain block given the block number.
-}
getTxByBlockNumberAndIndex : HttpProvider -> Int -> Int -> Task Http.Error Tx
getTxByBlockNumberAndIndex ethNode blockNumber txIndex =
    RPC.toTask
        { url = ethNode
        , method = "eth_getTransactionByBlockNumberAndIndex"
        , params = [ Encode.hexInt blockNumber, Encode.hexInt txIndex ]
        , decoder = Decode.tx
        }


{-| Execute a transaction on chain.
Only useful if your keys live on the node your talking too.

NOTE: You probably don't need this.
If you're writing a proper dApp, look at using the TxSentry to interface with wallets like MetaMask.

-}
sendTx : HttpProvider -> Send -> Task Http.Error TxHash
sendTx ethNode txParams =
    RPC.toTask
        { url = ethNode
        , method = "eth_sendTransaction"
        , params = [ encodeSend txParams ]
        , decoder = Decode.txHash
        }


{-| Broadcast a signed transaction
-}
sendRawTx : HttpProvider -> String -> Task Http.Error TxHash
sendRawTx ethNode signedTx =
    RPC.toTask
        { url = ethNode
        , method = "eth_sendRawTransaction"
        , params = [ Encode.string signedTx ]
        , decoder = Decode.txHash
        }



-- Address


{-| Get the balance of a given address/account.
Returns Wei amount as BigInt
-}
getBalance : HttpProvider -> Address -> Task Http.Error BigInt
getBalance ethNode address =
    getBalanceAtBlock ethNode address LatestBlock


{-| Get the balance of a given address/account, at a certain block height
-}
getBalanceAtBlock : HttpProvider -> Address -> BlockId -> Task Http.Error BigInt
getBalanceAtBlock ethNode address blockId =
    RPC.toTask
        { url = ethNode
        , method = "eth_getBalance"
        , params = [ Encode.address address, Encode.blockId blockId ]
        , decoder = Decode.bigInt
        }


{-| Get the number of transactions sent from a given address/account.
-}
getTxCount : HttpProvider -> Address -> Task Http.Error Int
getTxCount ethNode address =
    getTxCountAtBlock ethNode address LatestBlock


{-| Get the number of transactions sent from a given address/account at a given block height.
-}
getTxCountAtBlock : HttpProvider -> Address -> BlockId -> Task Http.Error Int
getTxCountAtBlock ethNode address blockId =
    RPC.toTask
        { url = ethNode
        , method = "eth_getTransactionCount"
        , params = [ Encode.address address, Encode.blockId blockId ]
        , decoder = Decode.hexInt
        }



-- Blocks


{-| Get the number of the most recent block.
-}
getBlockNumber : HttpProvider -> Task Http.Error Int
getBlockNumber ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_blockNumber"
        , params = []
        , decoder = Decode.hexInt
        }


{-| Get information about a block given a valid block number.

The transactions field will be an array of TxHash's mined during this block.

-}
getBlock : HttpProvider -> Int -> Task Http.Error (Block TxHash)
getBlock ethNode blockNum =
    RPC.toTask
        { url = ethNode
        , method = "eth_getBlockByNumber"
        , params = [ Encode.hexInt blockNum, Encode.bool False ]
        , decoder = Decode.block Decode.txHash
        }


{-| Get information about a block given a valid block hash.
-}
getBlockByHash : HttpProvider -> BlockHash -> Task Http.Error (Block TxHash)
getBlockByHash ethNode blockHash =
    RPC.toTask
        { url = ethNode
        , method = "eth_getBlockByHash"
        , params = [ Encode.blockHash blockHash, Encode.bool False ]
        , decoder = Decode.block Decode.txHash
        }


{-| See getBlock.

The transactions field will be an array of Tx objects instead of TxHash's.

-}
getBlockWithTxObjs : HttpProvider -> Int -> Task Http.Error (Block Tx)
getBlockWithTxObjs ethNode blockNum =
    RPC.toTask
        { url = ethNode
        , method = "eth_getBlockByNumber"
        , params = [ Encode.hexInt blockNum, Encode.bool True ]
        , decoder = Decode.block Decode.tx
        }


{-| See getBlockWithTxObjs.

Uses block hash instead of nunmber for the identifier.

-}
getBlockByHashWithTxObjs : HttpProvider -> BlockHash -> Task Http.Error (Block Tx)
getBlockByHashWithTxObjs ethNode blockHash =
    RPC.toTask
        { url = ethNode
        , method = "eth_getBlockByHash"
        , params = [ Encode.blockHash blockHash, Encode.bool True ]
        , decoder = Decode.block Decode.tx
        }


{-| Get the number of transactions in a block from a given block number.
-}
getBlockTxCount : HttpProvider -> Int -> Task Http.Error Int
getBlockTxCount ethNode blockNumber =
    RPC.toTask
        { url = ethNode
        , method = "eth_getBlockTransactionCountByNumber"
        , params = [ Encode.hexInt blockNumber ]
        , decoder = Decode.hexInt
        }


{-| Get the number of transactions in a block from a given block hash.
-}
getBlockTxCountByHash : HttpProvider -> BlockHash -> Task Http.Error Int
getBlockTxCountByHash ethNode blockHash =
    RPC.toTask
        { url = ethNode
        , method = "eth_getBlockTransactionCountByHash"
        , params = [ Encode.blockHash blockHash ]
        , decoder = Decode.hexInt
        }


{-| Get the number of uncles in a given block given a block number.
-}
getUncleCount : HttpProvider -> Int -> Task Http.Error Int
getUncleCount ethNode blockNumber =
    RPC.toTask
        { url = ethNode
        , method = "eth_getUncleCountByBlockNumber"
        , params = [ Encode.hexInt blockNumber ]
        , decoder = Decode.hexInt
        }


{-| Get the number of uncles in a given block given a block hash.
-}
getUncleCountByHash : HttpProvider -> BlockHash -> Task Http.Error Int
getUncleCountByHash ethNode blockHash =
    RPC.toTask
        { url = ethNode
        , method = "eth_getUncleCountByBlockHash"
        , params = [ Encode.blockHash blockHash ]
        , decoder = Decode.hexInt
        }


{-| Get information about an uncle given it's index in a block by block number
-}
getUncleAtIndex : HttpProvider -> Int -> Int -> Task Http.Error Uncle
getUncleAtIndex ethNode blockNumber uncleIndex =
    RPC.toTask
        { url = ethNode
        , method = "eth_getUncleByBlockNumberAndIndex"
        , params = [ Encode.hexInt blockNumber, Encode.hexInt uncleIndex ]
        , decoder = Decode.uncle
        }


{-| Get information about an uncle given it's index in a block by block hash
-}
getUncleByBlockHashAtIndex : HttpProvider -> BlockHash -> Int -> Task Http.Error Uncle
getUncleByBlockHashAtIndex ethNode blockHash uncleIndex =
    RPC.toTask
        { url = ethNode
        , method = "eth_getUncleByBlockHashAndIndex"
        , params = [ Encode.blockHash blockHash, Encode.hexInt uncleIndex ]
        , decoder = Decode.uncle
        }



-- Filters/Logs


{-| Get an array of all logs matching a given filter object.
Most likely you won't need this, as they are generated for you in elm-web3-contract
-}
getLogs : HttpProvider -> LogFilter -> Task Http.Error (List Log)
getLogs ethNode logFilter =
    RPC.toTask
        { url = ethNode
        , method = "eth_getLogs"
        , params = [ Encode.logFilter logFilter ]
        , decoder = Decode.list Decode.log
        }


{-| Establishes a filter object on a given node.
Useful for contract events.

To check if the state has changed, call getFilterChanges.

-}
newFilter : HttpProvider -> LogFilter -> Task Http.Error FilterId
newFilter ethNode logFilter =
    RPC.toTask
        { url = ethNode
        , method = "eth_newFilter"
        , params = [ Encode.logFilter logFilter ]
        , decoder = Decode.string
        }


{-| Creates a filter in the node to notify when a new block arrives.
To check if the state has changed, call getFilterChanges.
-}
newBlockFilter : HttpProvider -> Task Http.Error FilterId
newBlockFilter ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_newBlockFilter"
        , params = []
        , decoder = Decode.string
        }


{-| Creates a filter in the node to notify when new pending transactions arrive.
To check if the state has changed, call getFilterChanges.
-}
newPendingTxFilter : HttpProvider -> Task Http.Error FilterId
newPendingTxFilter ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_newPendingTransactionFilter"
        , params = []
        , decoder = Decode.string
        }


{-| Polling method for a filter, which returns an array of logs which occurred since last poll.

Use the correct decoder for the given filter type:

    newFilter : Event a
    newBlockFilter : BlockHeader?? TODO
    newPendingTxFilter : TxHash

-}
getFilterChanges : HttpProvider -> Decoder a -> FilterId -> Task Http.Error (List a)
getFilterChanges ethNode decoder filterId =
    RPC.toTask
        { url = ethNode
        , method = "eth_getFilterChanges"
        , params = []
        , decoder = Decode.list decoder
        }


{-| Returns an array of all logs matching filter with given id.
-}
getFilterLogs : HttpProvider -> Decoder a -> FilterId -> Task Http.Error (List a)
getFilterLogs ethNode decoder filterId =
    RPC.toTask
        { url = ethNode
        , method = "eth_getFilterLogs"
        , params = [ Encode.string filterId ]
        , decoder = Decode.list decoder
        }


{-| Uninstalls a filter with given id.
Should always be called when watch is no longer needed.
Additonally Filters timeout when they aren't requested with eth_getFilterChanges for a period of time.
-}
uninstallFilter : HttpProvider -> FilterId -> Task Http.Error FilterId
uninstallFilter ethNode filterId =
    RPC.toTask
        { url = ethNode
        , method = "eth_newPendingTransactionFilter"
        , params = []
        , decoder = Decode.string
        }



-- Other


{-| Sign an arbitrary chunk of N bytes.

The sign method calculates an Ethereum specific signature with: sign(keccak256("\x19Ethereum Signed Message:\n" + len(message) + message))).

By adding a prefix to the message makes the calculated signature recognisable as an Ethereum specific signature. This prevents misuse where a malicious DApp can sign arbitrary data (e.g. transaction) and use the signature to impersonate the victim.

Note the address to sign with must be unlocked.

-}
sign : HttpProvider -> Address -> String -> Task Http.Error String
sign ethNode address data =
    RPC.toTask
        { url = ethNode
        , method = "eth_sign"
        , params = [ Encode.address address, Encode.string data ]
        , decoder = Decode.string
        }


{-| Get the current ethereum protocol version.
-}
protocolVersion : HttpProvider -> Task Http.Error Int
protocolVersion ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_protocolVersion"
        , params = []
        , decoder = Decode.hexInt
        }


{-| Get the sync status of a particular node.

    Nothing == Not Syncing
    Just SyncStatus == starting, current, and highestBlock

-}
syncing : HttpProvider -> Task Http.Error (Maybe SyncStatus)
syncing ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_syncing"
        , params = []
        , decoder = Decode.syncStatus
        }


{-| Get the client's coinbase address.
-}
coinbase : HttpProvider -> Task Http.Error Address
coinbase ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_coinbase"
        , params = []
        , decoder = Decode.address
        }


{-| See whether or not a given node is mining.
-}
mining : HttpProvider -> Task Http.Error Bool
mining ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_mining"
        , params = []
        , decoder = Decode.bool
        }


{-| Returns the number of hashes per second that the node is mining with.
-}
hashrate : HttpProvider -> Task Http.Error Int
hashrate ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_hashrate"
        , params = []
        , decoder = Decode.hexInt
        }


{-| Get the current price per gas in wei

Note: not always accurate. See EthGasStation website

-}
gasPrice : HttpProvider -> Task Http.Error BigInt
gasPrice ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_gasPrice"
        , params = []
        , decoder = Decode.bigInt
        }


{-| Returns a list of addresses owned by client.
-}
accounts : HttpProvider -> Task Http.Error (List Address)
accounts ethNode =
    RPC.toTask
        { url = ethNode
        , method = "eth_accounts"
        , params = []
        , decoder = Decode.list Decode.address
        }
