module Web3.Eth.Encoders exposing (txParamsEncoder)

import Web3.Eth.Types exposing (TxParams)
import BigInt
import Json.Encode as Encode exposing (Value, string, int, null, object)


txParamsEncoder : TxParams -> Value
txParamsEncoder { from, to, value, gas, data, gasPrice, nonce } =
    [ ( "from", Just <| string from )
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
