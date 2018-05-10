module Internal.Encode exposing (..)

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


listOfMaybesToVal : List ( String, Maybe Value ) -> Value
listOfMaybesToVal keyValueList =
    keyValueList
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault Encode.null v ))
        |> Encode.object


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
blockId : BlockId -> Value
blockId blockId =
    case blockId of
        BlockNum num ->
            Hex.toString num
                |> add0x
                |> string

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


topicsList : List (Maybe Hex) -> Value
topicsList topicsList =
    let
        toVal val =
            case val of
                Just hex ->
                    string (hexToString hex)

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
