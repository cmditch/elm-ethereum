module Eth.Decode
    exposing
        ( address
        , hex
        , txHash
        , blockHash
        , event
        )

{-| Eth Decoders

@docs address, hex, txHash, blockHash, event

-}

import Eth.Types exposing (..)
import Eth.Utils exposing (toAddress, toHex, toTxHash, toBlockHash)
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



-- Useful with EventSentry


{-| -}
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
