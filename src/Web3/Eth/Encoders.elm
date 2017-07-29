module Web3.Eth.Encoders exposing (txParamsEncoder, filterParamsEncoder, txParamsToString, getBlockIdValue)

import Web3.Eth.Types exposing (..)
import BigInt
import Json.Encode as Encode exposing (Value, string, int, null, list, object)


txParamsEncoder : TxParams -> Value
txParamsEncoder { from, to, value, gas, data, gasPrice, nonce } =
    [ ( "from", Maybe.map string from )
    , ( "to", Maybe.map string to )
    , ( "value", Maybe.map (BigInt.toString >> string) value )
    , ( "gas", Maybe.map int gas )
    , ( "data", Maybe.map string data )
    , ( "gasPrice", Maybe.map int gasPrice )
    , ( "nonce", Maybe.map int nonce )
    ]
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault null v ))
        |> Encode.object


txParamsToString : TxParams -> String
txParamsToString { from, to, value, gas, data, gasPrice, nonce } =
    let
        strMap =
            Maybe.map toString

        wDef =
            Maybe.withDefault ""
    in
        [ ( "{ ", Just "", "" )
        , ( "from: '", from, "', " )
        , ( "to: '", to, "', " )
        , ( "value: '", Maybe.map BigInt.toString value, "', " )
        , ( "gas: '", strMap gas, "', " )
        , ( "data: '", data, "', " )
        , ( "gasPrice: '", strMap gasPrice, "', " )
        , ( "nonce: '", strMap nonce, "', " )
        , ( "}", Just "", "" )
        ]
            |> List.filter (\( k, v, d ) -> v /= Nothing)
            |> List.map (\( k, v, d ) -> k ++ (wDef v) ++ d)
            |> String.join ""


filterParamsEncoder : FilterParams -> Value
filterParamsEncoder { fromBlock, toBlock, address, topics } =
    [ ( "fromBlock", Maybe.map getBlockIdValue fromBlock )
    , ( "toBlock", Maybe.map getBlockIdValue toBlock )
    , ( "address", Maybe.map string address )
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
            Encode.string hash

        Earliest ->
            Encode.string "earliest"

        Latest ->
            Encode.string "latest"

        Pending ->
            Encode.string "pending"
