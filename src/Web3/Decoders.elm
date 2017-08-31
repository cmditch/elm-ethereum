module Web3.Decoders
    exposing
        ( blockDecoder
        , blockTxIdDecoder
        , blockTxObjDecoder
        , txObjDecoder
        , txReceiptDecoder
        , logDecoder
        , addressDecoder
        , txIdDecoder
        , bytesDecoder
        , hexDecoder
        , byteArrayDecoder
        , blockNumDecoder
        , bigIntDecoder
        , toAsciiDecoder
        , syncStatusDecoder
        , contractInfoDecoder
        , eventLogDecoder
        , bytesToString
        , hexToString
        , addressToString
        , txIdToString
        , expectInt
        , expectString
        , expectBool
        , expectJson
        , expectBigInt
        )

import BigInt exposing (BigInt)
import Json.Decode as Decode exposing (int, list, nullable, string, bool, Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Web3.Types exposing (..)
import Web3.Internal exposing (expectStringResponse)


blockDecoder : Decoder a -> Decoder (Block a)
blockDecoder decoder =
    decode Block
        |> optional "author" (nullable addressDecoder) Nothing
        |> required "difficulty" bigIntDecoder
        |> required "extraData" string
        |> required "gasLimit" int
        |> required "gasUsed" int
        |> required "hash" blockHashDecoder
        |> required "logsBloom" string
        |> required "miner" string
        |> required "mixHash" string
        |> required "nonce" string
        |> required "number" int
        |> required "parentHash" string
        |> required "receiptsRoot" string
        |> optional "sealFields" (list string) []
        |> required "sha3Uncles" string
        |> required "size" int
        |> required "stateRoot" string
        |> required "timestamp" int
        |> required "totalDifficulty" bigIntDecoder
        |> optional "transactions" (list decoder) []
        |> required "transactionsRoot" string
        |> required "uncles" (list string)


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
        |> required "creates" (nullable addressDecoder)
        |> required "from" addressDecoder
        |> required "gas" int
        |> required "gasPrice" bigIntDecoder
        |> required "hash" txIdDecoder
        |> required "input" bytesDecoder
        |> required "networkId" (nullable int)
        |> required "nonce" int
        |> required "publicKey" hexDecoder
        |> required "r" hexDecoder
        |> required "raw" bytesDecoder
        |> required "s" hexDecoder
        |> required "standardV" hexDecoder
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
        |> required "contractAddress" string
        |> required "logs" (list logDecoder)


logDecoder : Decoder Log
logDecoder =
    decode Log
        |> required "address" addressDecoder
        |> required "blockHash" (nullable string)
        |> required "blockNumber" (nullable int)
        |> required "data" string
        |> required "logIndex" (nullable int)
        |> required "topics" (list string)
        |> required "transactionHash" txIdDecoder
        |> required "transactionIndex" int
        |> required "transactionLogIndex" string
        |> required "type_" string


eventLogDecoder : Decoder a -> Decoder (EventLog a)
eventLogDecoder argsDecoder =
    decode EventLog
        |> required "address" addressDecoder
        |> required "args" argsDecoder
        |> required "blockHash" (nullable string)
        |> required "blockNumber" (nullable int)
        |> optional "event" string "Error"
        |> required "logIndex" (nullable int)
        |> required "transactionHash" txIdDecoder
        |> required "transactionIndex" int


addressDecoder : Decoder Address
addressDecoder =
    specialTypeDecoder Address


txIdDecoder : Decoder TxId
txIdDecoder =
    specialTypeDecoder TxId


bytesDecoder : Decoder Bytes
bytesDecoder =
    specialTypeDecoder Bytes


hexDecoder : Decoder Hex
hexDecoder =
    specialTypeDecoder Hex


byteArrayDecoder : Decoder ByteArray
byteArrayDecoder =
    list int |> Decode.andThen (ByteArray >> Decode.succeed)


blockNumDecoder : Decoder BlockId
blockNumDecoder =
    int |> Decode.andThen (BlockNum >> Decode.succeed)


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


specialTypeDecoder : (String -> a) -> Decoder a
specialTypeDecoder wrapper =
    string |> Decode.andThen (wrapper >> Decode.succeed)


contractInfoDecoder : Decoder ContractInfo
contractInfoDecoder =
    decode ContractInfo
        |> required "contractAddress" addressDecoder
        |> required "transactionHash" txIdDecoder


syncStatusDecoder : Decoder SyncStatus
syncStatusDecoder =
    decode SyncStatus
        |> required "startingBlock" int
        |> required "currentBlock" int
        |> required "highestBlock" int


addressToString : Address -> String
addressToString (Address address) =
    address


txIdToString : TxId -> String
txIdToString (TxId txId) =
    txId


bytesToString : Bytes -> String
bytesToString (Bytes bytes) =
    bytes


hexToString : Hex -> String
hexToString (Hex hex) =
    hex


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
