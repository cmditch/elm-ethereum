module Web3.Eth.Encode
    exposing
        ( address
        , txHash
        , blockHash
        , txCall
        , txSend
        , blockId
        , logFilter
        )

{-| Eth Encoders


# Simple

@docs address, txHash, blockHash


# Complex

@docs txCall, txSend, blockId, logFilter

-}

import Hex
import Json.Encode exposing (Value, int, list, string, object, null)
import Web3.Internal.Utils exposing (listOfMaybesToVal)
import Web3.Utils exposing (..)
import Web3.Eth.Types exposing (..)
import Web3.Encode exposing (hex, bigInt, hexInt)


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


addressList : List Address -> Value
addressList =
    List.map address >> list
