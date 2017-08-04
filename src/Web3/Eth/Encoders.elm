module Web3.Eth.Encoders
    exposing
        ( txParamsEncoder
        , filterParamsEncoder
        , txParamsToString
        , getBlockIdValue
        , addressMaybeMap
        , encodeFilter
        )

import Web3.Eth.Types exposing (..)
import Web3.Eth.Decoders exposing (bytesToString, addressToString, hexToString)
import BigInt
import Json.Encode as Encode exposing (Value, string, int, null, list, object)


txParamsEncoder : TxParams -> Value
txParamsEncoder { from, to, value, gas, data, gasPrice, nonce } =
    [ ( "from", Maybe.map string (addressMaybeMap from) )
    , ( "to", Maybe.map string (addressMaybeMap to) )
    , ( "value", Maybe.map (BigInt.toString >> string) value )
    , ( "gas", Maybe.map int gas )
    , ( "data", Maybe.map string (bytesMaybeMap data) )
    , ( "gasPrice", Maybe.map int gasPrice )
    , ( "nonce", Maybe.map int nonce )
    ]
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault null v ))
        |> Encode.object


txParamsToString : TxParams -> String
txParamsToString { from, to, value, gas, data, gasPrice, nonce } =
    let
        wDef =
            Maybe.withDefault ""
    in
        [ ( "{ ", Just "", "" )
        , ( "from: '", addressMaybeMap from, "', " )
        , ( "to: '", addressMaybeMap to, "', " )
        , ( "value: '", Maybe.map BigInt.toString value, "', " )
        , ( "gas: '", intMaybeMap gas, "', " )
        , ( "data: '", bytesMaybeMap data, "', " )
        , ( "gasPrice: '", intMaybeMap gasPrice, "', " )
        , ( "nonce: '", intMaybeMap nonce, "', " )
        , ( "}", Just "", "" )
        ]
            |> List.filter (\( k, v, d ) -> v /= Nothing)
            |> List.map (\( k, v, d ) -> k ++ (wDef v) ++ d)
            |> String.join ""


filterParamsEncoder : FilterParams -> Value
filterParamsEncoder { fromBlock, toBlock, address, topics } =
    [ ( "fromBlock", Maybe.map getBlockIdValue fromBlock )
    , ( "toBlock", Maybe.map getBlockIdValue toBlock )
    , ( "address", Maybe.map string (addressMaybeMap address) )
    , ( "topics", Maybe.map maybeStringListEncoder topics )
    ]
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault null v ))
        |> Encode.object


maybeStringListEncoder : List (Maybe String) -> Value
maybeStringListEncoder mList =
    let
        toVal val =
            case val of
                Just str ->
                    string str

                Nothing ->
                    null
    in
        List.map toVal mList |> Encode.list


getBlockIdValue : BlockId -> Encode.Value
getBlockIdValue blockId =
    case blockId of
        BlockNum number ->
            Encode.int number

        BlockHash hash ->
            Encode.string (hexToString hash)

        Earliest ->
            Encode.string "earliest"

        Latest ->
            Encode.string "latest"

        Pending ->
            Encode.string "pending"


bytesMaybeMap : Maybe Bytes -> Maybe String
bytesMaybeMap =
    Maybe.map bytesToString


addressMaybeMap : Maybe Address -> Maybe String
addressMaybeMap =
    Maybe.map addressToString


intMaybeMap : Maybe Int -> Maybe String
intMaybeMap =
    Maybe.map toString


encodeFilter : List ( String, Maybe Value ) -> Value
encodeFilter object =
    object
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault Encode.null v ))
        |> Encode.object
