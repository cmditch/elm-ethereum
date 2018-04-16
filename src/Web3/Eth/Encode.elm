module Web3.Eth.Encode exposing (..)

import Json.Encode exposing (Value, int, list, string, object, null)
import Web3.Internal.Utils exposing (listOfMaybesToVal)
import Web3.Utils exposing (addressToString, hexToString, txHashToString)
import Web3.Types exposing (..)
import Web3.Encode exposing (hex, bigInt)


address : Address -> Value
address =
    addressToString >> string


txHash : TxHash -> Value
txHash =
    txHashToString >> string


addressList : List Address -> Value
addressList =
    List.map address >> list


callParams : TxParams a -> Value
callParams { to, from, gas, gasPrice, value, data } =
    listOfMaybesToVal
        [ ( "to", Maybe.map address to )
        , ( "from", Maybe.map address from )
        , ( "gas", Maybe.map int gas )
        , ( "gasPrice", Maybe.map bigInt gasPrice )
        , ( "value", Maybe.map bigInt value )
        , ( "data", Maybe.map hex data )
        ]


sendParams : Send -> Value
sendParams { to, from, gas, gasPrice, value, data, nonce } =
    listOfMaybesToVal
        [ ( "to", Maybe.map address to )
        , ( "from", Maybe.map address from )
        , ( "gas", Maybe.map int gas )
        , ( "gasPrice", Maybe.map bigInt gasPrice )
        , ( "value", Maybe.map bigInt value )
        , ( "data", Maybe.map hex data )
        , ( "nonce", Maybe.map int nonce )
        ]


blockId : BlockId -> Value
blockId blockId =
    case blockId of
        BlockNum num ->
            int num

        BlockHash blockHash ->
            string (hexToString blockHash)

        Earliest ->
            string "earliest"

        Latest ->
            string "latest"

        Pending ->
            string "pending"


logFilter : LogFilter -> Value
logFilter logFilter =
    object
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
                    string str

                Nothing ->
                    null
    in
        List.map toVal topicsList |> list
