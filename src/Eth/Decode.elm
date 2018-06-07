module Eth.Decode
    exposing
        ( address
        , hex
        , txHash
        , blockHash
        , ipfsHash
        , event
        , blockHead
        , tx
        )

{-| Eth Decoders

@docs address, hex, txHash, blockHash, ipfsHash, event, blockHead, tx

-}

import Eth.Types exposing (..)
import Eth.Utils exposing (toAddress, toHex, toTxHash, toBlockHash, toIPFSHash)
import Internal.Decode exposing (stringInt, hexInt, bigInt, hexTime, hexBool, resultToDecoder, nonZero)
import Json.Decode as Decode exposing (Decoder, string, bool, list, nullable)
import Json.Decode.Pipeline exposing (required, decode, custom)


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


{-| -}
ipfsHash : Decoder IPFSHash
ipfsHash =
    resultToDecoder toIPFSHash


{-| Used by [elm-ethereum-generator](https://github.com/cmditch/elm-ethereum-generator)

Useful with `Eth.Sentry.Event` and `LogFilter` related functions in `Eth` module.

-}
event : Decoder a -> Decoder (Event a)
event returnDataDecoder =
    decode Event
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
    decode BlockHead
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
    decode Tx
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
