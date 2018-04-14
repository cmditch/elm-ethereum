module Web3.Decode exposing (..)

-- Library

import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (required, decode, custom)
import Hex


-- Internal

import Web3.Utils exposing (remove0x)
import Web3.Types exposing (..)


-- Decoders


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



-- {-| -}
-- txReceiptDecoder : Decoder TxReceipt
-- txReceiptDecoder =
--     decode TxReceipt
--         |> required "transactionHash" txIdDecoder
--         |> required "transactionIndex" int
--         |> required "blockHash" string
--         |> required "blockNumber" int
--         |> required "gasUsed" int
--         |> required "cumulativeGasUsed" int
--         |> custom (maybe (field "contractAddress" addressDecoder))
--         |> required "logs" (list logDecoder)
-- {-| -}
-- logDecoder : Decoder Log
-- logDecoder =
--     decode Log
--         |> required "address" addressDecoder
--         |> required "data" string
--         |> required "topics" (list string)
--         |> required "logIndex" (nullable int)
--         |> required "transactionIndex" int
--         |> required "transactionHash" txIdDecoder
--         |> required "blockHash" (nullable string)
--         |> required "blockNumber" (nullable int)


hexInt : Decoder Int
hexInt =
    let
        convert n =
            case Hex.fromString (remove0x n) of
                Ok int ->
                    Decode.succeed int

                Err error ->
                    Decode.fail error
    in
        Decode.string |> Decode.andThen convert


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


{-| -}
stringyType : (String -> a) -> Decoder a
stringyType wrapper =
    string |> Decode.andThen (wrapper >> Decode.succeed)
