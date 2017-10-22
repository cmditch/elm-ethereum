module Web3.Encoders
    exposing
        ( encodeTxParams
        , encodeFilterParams
        , encodeAddressList
        , encodeBigIntList
        , encodeListBigIntList
        , encodeIntList
        , encodeKeystore
        , encodeKeystoreList
        , getBlockIdValue
        , listOfMaybesToVal
        , encodeBytes
          -- , encodeCustomTxParams
        )

import Web3.Types exposing (..)
import Web3.Decoders exposing (addressToString, hexToString)
import BigInt exposing (BigInt)
import Json.Encode as Encode exposing (Value, string, int, null, list, object)


encodeTxParams : Maybe Address -> TxParams -> Value
encodeTxParams from { to, value, gas, data, gasPrice, nonce, chainId } =
    listOfMaybesToVal
        [ ( "from", Maybe.map (addressToString >> string) from )
        , ( "to", Maybe.map (addressToString >> string) to )
        , ( "value", Maybe.map (BigInt.toString >> string) value )
        , ( "gas", Maybe.map int (Just gas) )
        , ( "data", Maybe.map (hexToString >> string) data )
        , ( "gasPrice", Maybe.map int gasPrice )
        , ( "nonce", Maybe.map int nonce )
        , ( "chainId", Maybe.map int chainId )
        ]



-- encodeCustomTxParams : List ( String, Maybe Value ) -> TxParams -> Value
-- encodeCustomTxParams customFields { from, to, value, gas, data, gasPrice, nonce, chainId } =
--     listOfMaybesToVal <|
--         [ ( "from", Maybe.map string (addressMaybeMap from) )
--         , ( "to", Maybe.map string (addressMaybeMap to) )
--         , ( "value", Maybe.map (BigInt.toString >> string) value )
--         , ( "gas", Maybe.map int (Just gas) )
--         , ( "data", Maybe.map string (hexMaybeMap data) )
--         , ( "gasPrice", Maybe.map int gasPrice )
--         , ( "nonce", Maybe.map int nonce )
--         , ( "chainId", Maybe.map int chainId )
--         ]
--             ++ customFields


encodeFilterParams : LogParams -> Value
encodeFilterParams { fromBlock, toBlock, address, topics } =
    Encode.object
        [ ( "fromBlock", getBlockIdValue fromBlock )
        , ( "toBlock", getBlockIdValue toBlock )
        , ( "address", encodeAddressList address )
        , ( "topics", topicsListEncoder topics )
        ]


getBlockIdValue : BlockId -> Value
getBlockIdValue blockId =
    case blockId of
        BlockNum num ->
            int num

        BlockHash hash ->
            string hash

        Earliest ->
            string "earliest"

        Latest ->
            string "latest"

        Pending ->
            string "pending"


topicsListEncoder : List (Maybe (List String)) -> Value
topicsListEncoder topicsList =
    let
        toVal val =
            case val of
                Just listOfStr ->
                    List.map string listOfStr |> list

                Nothing ->
                    null
    in
        List.map toVal topicsList |> list


encodeAddressList : List Address -> Value
encodeAddressList =
    List.map (addressToString >> string)
        >> list


encodeBigIntList : List BigInt -> Value
encodeBigIntList =
    List.map (BigInt.toString >> string)
        >> list


encodeListBigIntList : List (List BigInt) -> Value
encodeListBigIntList =
    List.map encodeBigIntList
        >> list


encodeIntList : List Int -> Value
encodeIntList =
    List.map int >> list


intMaybeMap : Maybe Int -> Maybe String
intMaybeMap =
    Maybe.map toString


listOfMaybesToVal : List ( String, Maybe Value ) -> Value
listOfMaybesToVal keyValueList =
    keyValueList
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault null v ))
        |> object


encodeBytes : Bytes -> Value
encodeBytes (Bytes byteArray) =
    list <| List.map int byteArray


encodeKeystore : Keystore -> Value
encodeKeystore keystore =
    let
        encodeCrypto crypto =
            object
                [ ( "ciphertext", string crypto.ciphertext )
                , ( "cipherparams", object [ ( "iv", string crypto.cipherparams.iv ) ] )
                , ( "cipher", string crypto.cipher )
                , ( "kdf", string crypto.kdf )
                , ( "kdfparams", encodeKdfParams crypto.kdfparams )
                , ( "mac", string crypto.mac )
                ]

        encodeKdfParams params =
            object
                [ ( "dklen", int params.dklen )
                , ( "salt", string params.salt )
                , ( "n", int params.n )
                , ( "r", int params.r )
                , ( "p", int params.p )
                ]
    in
        object
            [ ( "version", int keystore.version )
            , ( "id", string keystore.id )
            , ( "address", string keystore.address )
            , ( "crypto", encodeCrypto keystore.crypto )
            ]


encodeKeystoreList : List Keystore -> Value
encodeKeystoreList keystores =
    List.map encodeKeystore keystores |> Encode.list
