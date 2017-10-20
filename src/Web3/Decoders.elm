module Web3.Decoders
    exposing
        ( decodeWeb3String
        , blockDecoder
        , blockHeaderDecoder
        , blockTxIdDecoder
        , blockTxObjDecoder
        , txObjDecoder
        , txReceiptDecoder
        , logDecoder
        , addressDecoder
        , txIdDecoder
        , bytesDecoder
        , hexDecoder
        , sha3Decoder
        , keystoreDecoder
        , privateKeyDecoder
        , accountDecoder
        , signedTxDecoder
        , rpcSignedTxDecoder
        , signedMsgDecoder
        , blockNumDecoder
        , networkTypeDecoder
        , bigIntDecoder
        , toAsciiDecoder
        , syncStatusDecoder
        , contractInfoDecoder
        , eventLogDecoder
        , hexToString
        , addressToString
        , txIdToString
        , sha3ToString
        , privateKeyToString
        , expectInt
        , expectString
        , expectBool
        , expectJson
        , expectBigInt
        )

import BigInt exposing (BigInt)
import Json.Decode as Decode exposing (int, list, nullable, string, bool, maybe, field, Decoder)
import Json.Decode.Pipeline exposing (..)
import Web3.Types exposing (..)
import Web3.Internal exposing (expectStringResponse, Expect)


decodeWeb3String : Decoder a -> String -> Result Error a
decodeWeb3String decoder =
    Decode.decodeString decoder >> Result.mapError Error


blockDecoder : Decoder a -> Decoder (Block a)
blockDecoder decoder =
    decode Block
        |> optional "miner" (nullable addressDecoder) Nothing
        |> required "difficulty" bigIntDecoder
        |> required "extraData" string
        |> required "gasLimit" int
        |> required "gasUsed" int
        |> required "hash" blockHashDecoder
        |> required "logsBloom" string
        |> required "mixHash" string
        |> required "nonce" string
        |> required "number" int
        |> required "parentHash" string
        |> required "receiptsRoot" string
        |> required "sha3Uncles" string
        |> required "size" int
        |> required "stateRoot" string
        |> required "timestamp" int
        |> required "totalDifficulty" bigIntDecoder
        |> optional "transactions" (list decoder) []
        |> required "transactionsRoot" string
        |> required "uncles" (list string)


blockHeaderDecoder : Decoder BlockHeader
blockHeaderDecoder =
    decode BlockHeader
        |> optional "miner" (nullable addressDecoder) Nothing
        |> required "difficulty" bigIntDecoder
        |> required "extraData" string
        |> required "gasLimit" int
        |> required "gasUsed" int
        |> required "hash" blockHashDecoder
        |> required "logsBloom" string
        |> required "mixHash" string
        |> required "nonce" string
        |> required "number" int
        |> required "parentHash" string
        |> required "receiptsRoot" string
        |> required "sha3Uncles" string
        |> required "stateRoot" string
        |> required "timestamp" int
        |> required "transactionsRoot" string


blockTxIdDecoder : Decoder (Block TxId)
blockTxIdDecoder =
    blockDecoder txIdDecoder


blockTxObjDecoder : Decoder (Block TxObj)
blockTxObjDecoder =
    blockDecoder txObjDecoder


txObjDecoder : Decoder TxObj
txObjDecoder =
    decode TxObj
        |> required "blockHash" blockHashDecoder
        |> required "blockNumber" int
        |> custom (maybe (field "creates" addressDecoder))
        |> required "from" addressDecoder
        |> required "gas" int
        |> required "gasPrice" bigIntDecoder
        |> required "hash" txIdDecoder
        |> required "input" hexDecoder
        |> custom (maybe (field "networkId" int))
        |> required "nonce" int
        |> optional "publicKey" hexDecoder (Hex "0x0")
        |> required "r" hexDecoder
        |> optional "raw" hexDecoder (Hex "0x0")
        |> required "s" hexDecoder
        |> optional "standardV" hexDecoder (Hex "0x0")
        |> required "to" (nullable addressDecoder)
        |> optional "logs" (list logDecoder) []
        |> required "transactionIndex" int
        |> required "v" hexDecoder
        |> required "value" bigIntDecoder


txReceiptDecoder : Decoder TxReceipt
txReceiptDecoder =
    decode TxReceipt
        |> required "transactionHash" txIdDecoder
        |> required "transactionIndex" int
        |> required "blockHash" blockHashDecoder
        |> required "blockNumber" int
        |> required "gasUsed" int
        |> required "cumulativeGasUsed" int
        |> custom (maybe (field "contractAddress" addressDecoder))
        |> required "logs" (list logDecoder)


logDecoder : Decoder Log
logDecoder =
    decode Log
        |> required "address" addressDecoder
        |> required "data" string
        |> required "topics" (list string)
        |> required "logIndex" (nullable int)
        |> required "transactionIndex" int
        |> required "transactionHash" txIdDecoder
        |> required "blockHash" (nullable string)
        |> required "blockNumber" (nullable int)


eventLogDecoder : Decoder a -> Decoder (EventLog a)
eventLogDecoder returnValuesDecoder =
    let
        rawDecoder =
            decode (\data topics -> { data = data, topics = topics })
                |> required "data" hexDecoder
                |> required "topics" (list hexDecoder)
    in
        decode EventLog
            |> required "address" addressDecoder
            |> required "blockHash" (nullable string)
            |> required "blockNumber" (nullable int)
            |> required "transactionHash" txIdDecoder
            |> required "transactionIndex" int
            |> required "logIndex" (nullable int)
            |> required "removed" bool
            |> required "id" string
            |> required "returnValues" returnValuesDecoder
            |> optional "event" string "Are you seeing this? Open github issue plz"
            |> required "signature" (nullable hexDecoder)
            |> required "raw" rawDecoder


accountDecoder : Decoder Account
accountDecoder =
    decode Account
        |> required "address" addressDecoder
        |> required "privateKey" privateKeyDecoder


signedTxDecoder : Decoder SignedTx
signedTxDecoder =
    decode SignedTx
        |> required "messageHash" sha3Decoder
        |> required "r" hexDecoder
        |> required "s" hexDecoder
        |> required "v" hexDecoder
        |> required "rawTransaction" hexDecoder


rpcSignedTxDecoder : Decoder SignedTx
rpcSignedTxDecoder =
    decode SignedTx
        |> requiredAt [ "tx", "hash" ] sha3Decoder
        |> requiredAt [ "tx", "r" ] hexDecoder
        |> requiredAt [ "tx", "s" ] hexDecoder
        |> requiredAt [ "tx", "v" ] hexDecoder
        |> required "raw" hexDecoder


signedMsgDecoder : Decoder SignedMsg
signedMsgDecoder =
    decode SignedMsg
        |> custom (maybe (field "message" string))
        |> required "messageHash" sha3Decoder
        |> required "r" hexDecoder
        |> required "s" hexDecoder
        |> required "v" hexDecoder
        |> required "signature" hexDecoder


keystoreDecoder : Decoder Keystore
keystoreDecoder =
    decode Keystore
        |> required "version" int
        |> required "id" string
        |> required "address" string
        |> required "crypto" cryptoDecoder


cryptoDecoder : Decoder Crypto
cryptoDecoder =
    let
        cipherparamsDecoder =
            decode (\iv -> { iv = iv }) |> required "iv" string

        kdfparamsDecoder =
            decode (\dklen salt n r p -> { dklen = dklen, salt = salt, n = n, r = r, p = p })
                |> required "dklen" int
                |> required "salt" string
                |> required "n" int
                |> required "r" int
                |> required "p" int
    in
        decode Crypto
            |> required "ciphertext" string
            |> required "cipherparams" cipherparamsDecoder
            |> required "cipher" string
            |> required "kdf" string
            |> required "kdfparams" kdfparamsDecoder
            |> required "mac" string


addressDecoder : Decoder Address
addressDecoder =
    stringyTypeDecoder Address


txIdDecoder : Decoder TxId
txIdDecoder =
    stringyTypeDecoder TxId


hexDecoder : Decoder Hex
hexDecoder =
    stringyTypeDecoder Hex


sha3Decoder : Decoder Sha3
sha3Decoder =
    stringyTypeDecoder Sha3


privateKeyDecoder : Decoder PrivateKey
privateKeyDecoder =
    stringyTypeDecoder PrivateKey


stringyTypeDecoder : (String -> a) -> Decoder a
stringyTypeDecoder wrapper =
    string |> Decode.andThen (wrapper >> Decode.succeed)


bytesDecoder : Decoder Bytes
bytesDecoder =
    list int |> Decode.andThen (Bytes >> Decode.succeed)


blockNumDecoder : Decoder BlockId
blockNumDecoder =
    int |> Decode.andThen (BlockNum >> Decode.succeed)


networkTypeDecoder : Decoder Network
networkTypeDecoder =
    let
        toNetworkType stringyNetwork =
            case stringyNetwork of
                "main" ->
                    Decode.succeed MainNet

                "morden" ->
                    Decode.succeed Morden

                "ropsten" ->
                    Decode.succeed Ropsten

                "kovan" ->
                    Decode.succeed Kovan

                "private" ->
                    Decode.succeed Private

                _ ->
                    Decode.succeed Private
    in
        string |> Decode.andThen toNetworkType


blockHashDecoder : Decoder BlockId
blockHashDecoder =
    string |> Decode.andThen (BlockHash >> Decode.succeed)


bigIntDecoder : Decoder BigInt
bigIntDecoder =
    let
        convert stringyBigInt =
            case stringyBigInt |> BigInt.fromString of
                Just bigint ->
                    Decode.succeed bigint

                Nothing ->
                    Decode.fail "Error decoding BigInt"
    in
        string |> Decode.andThen convert


toAsciiDecoder : Decoder String
toAsciiDecoder =
    let
        removeNulls =
            String.split "\x00"
                >> String.join ""
                >> Decode.succeed
    in
        string |> Decode.andThen removeNulls


contractInfoDecoder : Decoder ContractInfo
contractInfoDecoder =
    decode ContractInfo
        |> required "contractAddress" addressDecoder
        |> required "transactionHash" txIdDecoder


syncStatusDecoder : Decoder (Maybe SyncStatus)
syncStatusDecoder =
    decode SyncStatus
        |> required "startingBlock" int
        |> required "currentBlock" int
        |> required "highestBlock" int
        |> required "knownStates" int
        |> required "pulledStates" int
        |> maybe


addressToString : Address -> String
addressToString (Address address) =
    address


txIdToString : TxId -> String
txIdToString (TxId txId) =
    txId


hexToString : Hex -> String
hexToString (Hex hex) =
    hex


sha3ToString : Sha3 -> String
sha3ToString (Sha3 sha3) =
    sha3


privateKeyToString : PrivateKey -> String
privateKeyToString (PrivateKey privateKey) =
    privateKey


expectInt : Expect Int
expectInt =
    expectStringResponse (\r -> Decode.decodeString int r)


expectString : Expect String
expectString =
    expectStringResponse (\r -> Decode.decodeString string r)


expectBool : Expect Bool
expectBool =
    expectStringResponse (\r -> Decode.decodeString bool r)


expectJson : Decoder a -> Expect a
expectJson decoder =
    expectStringResponse (\r -> Decode.decodeString decoder r)


expectBigInt : Expect BigInt
expectBigInt =
    expectStringResponse (\r -> Decode.decodeString bigIntDecoder r)
