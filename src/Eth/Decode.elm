module Eth.Decode exposing (address, hex, txHash, blockHash, event, blockHead, tx)

{-| Eth Decoders

@docs address, hex, txHash, blockHash, ipfsHash, event, blockHead, tx

-}

import Eth.Types exposing (..)
import Eth.Utils exposing (toAddress, toBlockHash, toHex, toTxHash)
import Internal.Decode exposing (bigInt, hexInt, hexTime, nonZero, resultToDecoder)
import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (custom, required)


{-| -}
address : Decoder Address
address =
    resultToDecoder toAddress


{-| -}
hex : Decoder Hex
hex =
    resultToDecoder toHex


{-| -}
txHash : Decoder TxHash
txHash =
    resultToDecoder toTxHash


{-| -}
blockHash : Decoder BlockHash
blockHash =
    resultToDecoder toBlockHash


{-| Used by [elm-ethereum-generator](https://github.com/cmditch/elm-ethereum-generator)

Useful with `Eth.Sentry.Event` and `LogFilter` related functions in `Eth` module.

-}
event : Decoder a -> Decoder (Event a)
event returnDataDecoder =
    succeed Event
        |> required "address" address
        |> required "data" string
        |> required "topics" (list hex)
        |> required "removed" bool
        |> required "logIndex" hexInt
        |> required "transactionIndex" hexInt
        |> required "transactionHash" txHash
        |> required "blockHash" blockHash
        |> required "blockNumber" hexInt
        |> custom returnDataDecoder


{-| -}
blockHead : Decoder BlockHead
blockHead =
    succeed BlockHead
        |> required "number" hexInt
        |> required "hash" blockHash
        |> required "parentHash" blockHash
        |> required "nonce" string
        |> required "sha3Uncles" string
        |> required "logsBloom" string
        |> required "transactionsRoot" string
        |> required "stateRoot" string
        |> required "receiptsRoot" string
        |> required "miner" address
        |> required "difficulty" bigInt
        |> required "extraData" string
        |> required "gasLimit" hexInt
        |> required "gasUsed" hexInt
        |> required "mixHash" string
        |> required "timestamp" hexTime


{-| -}
tx : Decoder Tx
tx =
    succeed Tx
        |> required "hash" txHash
        |> required "nonce" hexInt
        |> required "blockHash" (nonZero blockHash)
        |> required "blockNumber" (nullable hexInt)
        |> required "transactionIndex" hexInt
        |> required "from" address
        |> required "to" (nullable address)
        |> required "value" bigInt
        |> required "gasPrice" bigInt
        |> required "gas" hexInt
        |> required "input" string
