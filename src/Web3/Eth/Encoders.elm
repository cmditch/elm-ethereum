module Web3.Eth.Encoders exposing (txParamsEncoder, txParamsToString)

import Web3.Eth.Types exposing (TxParams)
import BigInt
import Json.Encode as Encode exposing (Value, string, int, null, object)


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
