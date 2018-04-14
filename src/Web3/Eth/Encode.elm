module Web3.Eth.Encode exposing (..)

import BigInt exposing (BigInt)
import Json.Encode as Encode exposing (Value)
import Web3.Utils as Web3
import Web3.Types exposing (..)


address : Address -> Value
address =
    Web3.addressToString >> Encode.string


{-| -}
addressList : List Address -> Value
addressList =
    List.map address
        >> Encode.list


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
    Encode.object
        [ ( "id", Encode.int id )
        , ( "method", Encode.string method )
        , ( "params", Encode.list params )
        ]
