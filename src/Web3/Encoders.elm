module Web3.Encoders
    exposing
        ( encodeTxParams
        , encodeFilterParams
        , encodeAddressList
        , encodeBigIntList
        , encodeListBigIntList
        , encodeIntList
        , getBlockIdValue
        , addressMaybeMap
        , listOfMaybesToVal
        , encodeBytes
        )

import Web3.Types exposing (..)
import Web3.Decoders exposing (addressToString, hexToString)
import BigInt exposing (BigInt)
import Json.Encode as Encode exposing (Value, string, int, null, list, object)


encodeTxParams : TxParams -> Value
encodeTxParams { from, to, value, gas, data, gasPrice, nonce } =
    listOfMaybesToVal
        [ ( "from", Maybe.map string (addressMaybeMap from) )
        , ( "to", Maybe.map string (addressMaybeMap to) )
        , ( "value", Maybe.map (BigInt.toString >> string) value )
        , ( "gas", Maybe.map int gas )
        , ( "data", Maybe.map string (hexMaybeMap data) )
        , ( "gasPrice", Maybe.map int gasPrice )
        , ( "nonce", Maybe.map int nonce )
        ]


encodeFilterParams : FilterParams -> Value
encodeFilterParams { fromBlock, toBlock, address, topics } =
    listOfMaybesToVal
        [ ( "fromBlock", Maybe.map getBlockIdValue fromBlock )
        , ( "toBlock", Maybe.map getBlockIdValue toBlock )
        , ( "address", Maybe.map encodeAddressList address )
        , ( "topics", Maybe.map maybeStringListEncoder topics )
        ]


getBlockIdValue : BlockId -> Encode.Value
getBlockIdValue blockId =
    case blockId of
        BlockNum num ->
            Encode.int num

        BlockHash hash ->
            Encode.string hash

        Earliest ->
            Encode.string "earliest"

        Latest ->
            Encode.string "latest"

        Pending ->
            Encode.string "pending"


maybeStringListEncoder : List (Maybe String) -> Value
maybeStringListEncoder mList =
    let
        toVal val =
            case val of
                Just str ->
                    Encode.string str

                Nothing ->
                    Encode.null
    in
        List.map toVal mList |> Encode.list


encodeAddressList : List Address -> Value
encodeAddressList =
    List.map (addressToString >> Encode.string)
        >> Encode.list


encodeBigIntList : List BigInt -> Value
encodeBigIntList =
    List.map (BigInt.toString >> Encode.string)
        >> Encode.list


encodeListBigIntList : List (List BigInt) -> Value
encodeListBigIntList =
    List.map encodeBigIntList
        >> Encode.list


encodeIntList : List Int -> Value
encodeIntList =
    List.map Encode.int >> Encode.list


hexMaybeMap : Maybe Hex -> Maybe String
hexMaybeMap =
    Maybe.map hexToString


addressMaybeMap : Maybe Address -> Maybe String
addressMaybeMap =
    Maybe.map addressToString


intMaybeMap : Maybe Int -> Maybe String
intMaybeMap =
    Maybe.map toString


listOfMaybesToVal : List ( String, Maybe Value ) -> Value
listOfMaybesToVal object =
    object
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault Encode.null v ))
        |> Encode.object


encodeBytes : Bytes -> Value
encodeBytes (Bytes byteArray) =
    Encode.list <| List.map Encode.int byteArray
