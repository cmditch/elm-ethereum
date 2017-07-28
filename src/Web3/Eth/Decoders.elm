module Web3.Eth.Decoders
    exposing
        ( blockDecoder
        , blockTxObjDecoder
        , txObjDecoder
        , txReceiptDecoder
        , logDecoder
        , addressDecoder
        , bytesDecoder
        , hexDecoder
        , syncStatusDecoder
        , contractAddressDecoder
        )

import Web3.Types exposing (..)
import Web3.Eth.Types exposing (..)
import Web3.Decoders exposing (bigIntDecoder)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Json.Decode as Decode exposing (int, string, list, nullable, Decoder)


blockDecoder : Decoder Block
blockDecoder =
    decode Block
        |> optional "author" addressDecoder ""
        |> required "difficulty" bigIntDecoder
        |> required "extraData" string
        |> required "gasLimit" int
        |> required "gasUsed" int
        |> required "hash" string
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
        |> required "transactions" (list string)
        |> required "transactionsRoot" string
        |> required "uncles" (list string)


blockTxObjDecoder : Decoder BlockTxObjs
blockTxObjDecoder =
    decode BlockTxObjs
        |> optional "author" addressDecoder ""
        |> required "difficulty" bigIntDecoder
        |> required "extraData" string
        |> required "gasLimit" int
        |> required "gasUsed" int
        |> required "hash" string
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
        |> required "transactions" (list txObjDecoder)
        |> required "transactionsRoot" string
        |> required "uncles" (list string)


txObjDecoder : Decoder TxObj
txObjDecoder =
    decode TxObj
        |> required "blockHash" hexDecoder
        |> required "blockNumber" int
        |> required "creates" (nullable addressDecoder)
        |> required "from" addressDecoder
        |> required "gas" int
        |> required "gasPrice" bigIntDecoder
        |> required "hash" string
        |> required "input" bytesDecoder
        |> required "networkId" int
        |> required "nonce" int
        |> required "publicKey" hexDecoder
        |> required "r" hexDecoder
        |> required "raw" bytesDecoder
        |> required "s" hexDecoder
        |> required "standardV" hexDecoder
        |> required "to" (nullable addressDecoder)
        |> required "logs" (list logDecoder)
        |> required "transactionIndex" int
        |> required "v" hexDecoder
        |> required "value" bigIntDecoder


txReceiptDecoder : Decoder TxReceipt
txReceiptDecoder =
    decode TxReceipt
        |> required "transactionHash" string
        |> required "transactionIndex" int
        |> required "blockHash" string
        |> required "blockNumber" int
        |> required "gasUsed" int
        |> required "cumulativeGasUsed" int
        |> required "contractAddress" string
        |> required "logs" (list logDecoder)


logDecoder : Decoder Log
logDecoder =
    decode Log
        |> required "address" string
        |> required "blockHash" string
        |> required "blockNumber" int
        |> required "data" string
        |> required "logIndex" int
        |> required "topics" (list string)
        |> required "transactionHash" string
        |> required "transactionIndex" int
        |> required "transactionLogIndex" string
        |> required "type_" string


addressDecoder : Decoder Address
addressDecoder =
    string


bytesDecoder : Decoder Bytes
bytesDecoder =
    string


hexDecoder : Decoder Hex
hexDecoder =
    string



{--
--   ContractAddress & contractAddressDecoder
--   Helpers needed for Web3.Eth.Contract.pollForAddress
--   TODO Might not need these. Might be able to use Task.map
--}


contractAddressDecoder : Decoder ContractInfo
contractAddressDecoder =
    decode ContractInfo
        |> required "contractAddress" string
        |> required "transactionHash" string


syncStatusDecoder : Decoder SyncStatus
syncStatusDecoder =
    decode SyncStatus
        |> required "startingBlock" int
        |> required "currentBlock" int
        |> required "highestBlock" int
