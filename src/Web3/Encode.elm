module Web3.Encode exposing (..)

-- Libraries

import BigInt exposing (BigInt)
import Json.Encode as Encode exposing (Value)


-- Internal

import Web3.Types exposing (..)
import Web3.Utils exposing (listOfMaybesToVal, add0x)


-- Encoders


bigInt : BigInt -> Value
bigInt =
    BigInt.toHexString >> add0x >> Encode.string


address : Address -> Value
address (Address address) =
    Encode.string address


{-| -}
addressList : List Address -> Value
addressList =
    List.map address
        >> Encode.list


hex : Hex -> Value
hex (Hex data) =
    Encode.string data


callParams : TxParams a -> Value
callParams { to, from, gas, gasPrice, value, data } =
    listOfMaybesToVal
        [ ( "to", Maybe.map address to )
        , ( "from", Maybe.map address from )
        , ( "gas", Maybe.map Encode.int gas )
        , ( "gasPrice", Maybe.map bigInt gasPrice )
        , ( "value", Maybe.map bigInt value )
        , ( "data", Maybe.map hex data )
        ]


sendParams : Send -> Value
sendParams { to, from, gas, gasPrice, value, data, nonce } =
    listOfMaybesToVal
        [ ( "to", Maybe.map address to )
        , ( "from", Maybe.map address from )
        , ( "gas", Maybe.map Encode.int gas )
        , ( "gasPrice", Maybe.map bigInt gasPrice )
        , ( "value", Maybe.map bigInt value )
        , ( "data", Maybe.map hex data )
        , ( "nonce", Maybe.map Encode.int nonce )
        ]


blockId : BlockId -> Value
blockId blockId =
    case blockId of
        BlockNum num ->
            Encode.int num

        Earliest ->
            Encode.string "earliest"

        Latest ->
            Encode.string "latest"

        Pending ->
            Encode.string "pending"


logFilter : LogFilter -> Value
logFilter logFilter =
    Encode.object
        [ ( "fromBlock", blockId logFilter.fromBlock )
        , ( "toBlock", blockId logFilter.toBlock )
        , ( "address", address logFilter.address )
        , ( "topics", topicsList logFilter.topics )
        ]


{-| -}
topicsList : List (Maybe String) -> Value
topicsList topicsList =
    let
        toVal val =
            case val of
                Just str ->
                    Encode.string str

                Nothing ->
                    Encode.null
    in
        List.map toVal topicsList |> Encode.list


rpc : Int -> String -> List Value -> Value
rpc id method params =
    [ ( "id", Encode.int id )
    , ( "method", Encode.string method )
    , ( "params", Encode.list params )
    ]
        |> Encode.object
