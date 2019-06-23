module Eth.Encode exposing (address, bigInt, blockHash, blockId, hex, hexInt, listOfMaybesToVal, logFilter, topicsList, txCall, txHash)

{-|

@docs address, bigInt, blockHash, blockId, hex, hexInt, listOfMaybesToVal, logFilter, topicsList, txCall, txHash

-}

import BigInt exposing (BigInt)
import Eth.Types exposing (..)
import Eth.Utils exposing (..)
import Hex
import Json.Encode as Encode exposing (Value, int, list, null, object, string)



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
listOfMaybesToVal : List ( String, Maybe Value ) -> Value
listOfMaybesToVal keyValueList =
    keyValueList
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault Encode.null v ))
        |> Encode.object



-- {-| -}
-- txCall : Call a -> Value
-- txCall { to, from, gas, gasPrice, value, data } =
--     let
--         toVal callData =
--             listOfMaybesToVal
--                 [ ( "to", Maybe.map address to )
--                 , ( "from", Maybe.map address from )
--                 , ( "gas", Maybe.map hexInt gas )
--                 , ( "gasPrice", Maybe.map bigInt gasPrice )
--                 , ( "value", Maybe.map bigInt value )
--                 , ( "data", Maybe.map hex callData )
--                 ]
--     in
--     case data of
--         Nothing ->
--             Ok <| toVal Nothing
--         Just (Ok data_) ->
--             Ok <| toVal (Just data_)
--         Just (Err err) ->
--             Err err


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
blockId blockId_ =
    case blockId_ of
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
logFilter lf =
    object
        [ ( "fromBlock", blockId lf.fromBlock )
        , ( "toBlock", blockId lf.toBlock )
        , ( "address", address lf.address )
        , ( "topics", topicsList lf.topics )
        ]


{-| -}
topicsList : List (Maybe Hex) -> Value
topicsList topics =
    let
        toVal val =
            case val of
                Just hexVal ->
                    string (hexToString hexVal)

                Nothing ->
                    null
    in
    list toVal topics



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
