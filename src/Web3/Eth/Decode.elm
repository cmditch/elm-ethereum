module Web3.Eth.Decode exposing (..)

import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (required, decode, custom)
import Hex


-- Internal

import Web3.Decode exposing (resultToDecoder)
import Web3.Utils exposing (remove0x)
import Web3.Types exposing (..)


-- Rudimentary Types


{-| -}
address : Decoder Address
address =
    stringyType Address


{-| -}
txId : Decoder TxId
txId =
    stringyType TxId


{-| -}
hex : Decoder Hex
hex =
    stringyType Hex



-- Record Types


{-| -}
txReceipt : Decoder TxReceipt
txReceipt =
    decode TxReceipt
        |> required "transactionHash" txId
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
        |> required "hash" txId
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
        |> required "transactionHash" txId
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
        |> required "transactionHash" txId
        |> required "blockHash" (nullable string)
        |> required "blockNumber" (nullable string)
        |> custom returnDataDecoder
