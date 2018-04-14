module Web3.Eth.Decode exposing (..)

import Json.Decode as Decode exposing (Decoder, string, maybe, field, list, nullable)
import Json.Decode.Pipeline exposing (required, decode, custom)


-- Internal

import Web3.Decode exposing (resultToDecoder, hexInt)
import Web3.Types exposing (..)
import Web3.Utils exposing (remove0x, toAddress, toHex, toTxHash)


-- Rudimentary Types


{-| -}
address : Decoder Address
address =
    resultToDecoder toAddress


{-| -}
txHash : Decoder TxHash
txHash =
    resultToDecoder toTxHash


{-| -}
hex : Decoder Hex
hex =
    resultToDecoder toHex



-- Record Types


{-| -}
txReceipt : Decoder TxReceipt
txReceipt =
    decode TxReceipt
        |> required "transactionHash" txHash
        |> required "transactionIndex" string
        |> required "blockHash" string
        |> required "blockNumber" string
        |> required "gasUsed" string
        |> required "cumulativeGasUsed" string
        |> custom (maybe (field "contractAddress" address))
        |> required "logs" (list log)


{-| -}
tx : Decoder Tx
tx =
    decode Tx
        |> required "hash" txHash
        |> required "nonce" hexInt
        |> required "gas" hexInt
        |> required "input" string


{-| -}
log : Decoder Log
log =
    decode Log
        |> required "address" address
        |> required "data" string
        |> required "topics" (list string)
        |> required "logIndex" (nullable string)
        |> required "transactionIndex" string
        |> required "transactionHash" txHash
        |> required "blockHash" (nullable string)
        |> required "blockNumber" (nullable string)


{-| -}
event : Decoder a -> Decoder (Event a)
event returnDataDecoder =
    decode Event
        |> required "address" address
        |> required "data" string
        |> required "topics" (list string)
        |> required "logIndex" (nullable string)
        |> required "transactionIndex" string
        |> required "transactionHash" txHash
        |> required "blockHash" (nullable string)
        |> required "blockNumber" (nullable string)
        |> custom returnDataDecoder
