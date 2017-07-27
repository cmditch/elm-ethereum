module Web3.Eth.Decoders
    exposing
        ( blockDecoder
        , addressDecoder
        , contractAddressDecoder
        )

import Web3.Eth.Types exposing (Block, Address, Bytes, TxId)
import Web3.Decoders exposing (bigIntDecoder)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Json.Decode as Decode exposing (int, string, list, Decoder)


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


addressDecoder : Decoder Address
addressDecoder =
    string



{--
  ContractAddress & contractAddressDecoder
  Helpers needed for Web3.Eth.Contract.pollForAddress
--}


type alias ContractAddress =
    { contractAddress : Address }


contractAddressDecoder : Decoder Address
contractAddressDecoder =
    decode ContractAddress
        |> required "contractAddress" string
        |> Decode.map (\r -> r.contractAddress)
