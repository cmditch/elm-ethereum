module Eth.Encode
    exposing
        ( address
        , txHash
        , blockHash
        , txCall
        , txSend
        , blockId
        , logFilter
        , bigInt
        , hex
        , hexInt
        )

{-| Eth Encoders


# Simple

@docs address, txHash, blockHash


# Complex

@docs txCall, txSend, blockId, logFilter


# Rudiments

@docs bigInt, hex, hexInt

-}

import BigInt exposing (BigInt)
import Hex
import Json.Encode as Encode exposing (Value, int, list, string, object, null)
import Eth.Types exposing (..)
import Eth.Utils exposing (..)
import Internal.Utils exposing (..)


-- Simple


{-| -}
address : Address -> Value
address =
    addressToString >> string


{-| -}
txHash : TxHash -> Value
txHash =
    txHashToString >> string


{-| -}
blockHash : BlockHash -> Value
blockHash =
    blockHashToString >> string



-- Complex


{-| -}
txCall : Call a -> Value
txCall { to, from, gas, gasPrice, value, data } =
    listOfMaybesToVal
        [ ( "to", Maybe.map address to )
        , ( "from", Maybe.map address from )
        , ( "gas", Maybe.map hexInt gas )
        , ( "gasPrice", Maybe.map bigInt gasPrice )
        , ( "value", Maybe.map bigInt value )
        , ( "data", Maybe.map hex data )
        ]


{-| -}
txSend : Send -> Value
txSend { to, from, gas, gasPrice, value, data, nonce } =
    listOfMaybesToVal
        [ ( "to", Maybe.map address to )
        , ( "from", Maybe.map address from )
        , ( "gas", Maybe.map hexInt gas )
        , ( "gasPrice", Maybe.map bigInt gasPrice )
        , ( "value", Maybe.map bigInt value )
        , ( "data", Maybe.map hex data )
        , ( "nonce", Maybe.map hexInt nonce )
        ]


{-| -}
blockId : BlockId -> Value
blockId blockId =
    case blockId of
        BlockIdNum num ->
            Hex.toString num
                |> add0x
                |> string

        BlockIdHash hash ->
            blockHash hash

        EarliestBlock ->
            string "earliest"

        LatestBlock ->
            string "latest"

        PendingBlock ->
            string "pending"


{-| -}
logFilter : LogFilter -> Value
logFilter logFilter =
    object
        [ ( "fromBlock", blockId logFilter.fromBlock )
        , ( "toBlock", blockId logFilter.toBlock )
        , ( "address", address logFilter.address )
        , ( "topics", topicsList logFilter.topics )
        ]


topicsList : List (Maybe String) -> Value
topicsList topicsList =
    let
        toVal val =
            case val of
                Just str ->
                    string str

                Nothing ->
                    null
    in
        List.map toVal topicsList |> list



-- Rudiments


{-| -}
bigInt : BigInt -> Value
bigInt =
    BigInt.toHexString >> add0x >> Encode.string


{-| -}
hex : Hex -> Value
hex =
    hexToString >> Encode.string


{-| -}
hexInt : Int -> Value
hexInt =
    Hex.toString >> add0x >> Encode.string
