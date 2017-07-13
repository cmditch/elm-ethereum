port module Web3
    exposing
        ( Model
        , Request
        , Response
        , Block
        , init
        , handleResponse
        , getBlockNumber
        , getBlock
        , request
        , response
        , decodeBlockNumber
        , decodeBlock
        )

import Dict exposing (..)
import Json.Decode as Decode exposing (Value, int, string, float, Decoder, decodeValue, list)
import BigInt exposing (BigInt)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


init : Model msg
init =
    Model 0 Dict.empty


type Model msg
    = Model Int (Dict Id (Value -> msg))


type alias Id =
    Int


type alias Address =
    String


type alias Wei =
    BigInt


type alias Block =
    { author : String
    , difficulty : BigInt
    , extraData : String
    , gasLimit : Int
    , gasUsed : Int
    , hash : String
    , logsBloom : String
    , miner : String
    , mixHash : String
    , nonce : String
    , number : Int
    , parentHash : String
    , receiptsRoot : String
    , sealFields : String
    , sha3Uncles : String
    , size : Int
    , stateRoot : String
    , timestamp : Int
    , totalDifficulty : BigInt
    , transactions : List String
    , transactionsRoot : String
    , uncles : List String
    }


type alias Request =
    { func : String
    , args : List String
    , id : Int
    }


type alias Response =
    { id : Int
    , data : Value
    }


handleResponse : Model msg -> Id -> Maybe (Value -> msg)
handleResponse (Model counter dict) id =
    Dict.get id dict


getBlockNumber : Model msg -> (Value -> msg) -> ( Model msg, Cmd msg )
getBlockNumber (Model counter dict) msg =
    let
        newCounter =
            counter + 1

        state_ =
            Dict.insert counter msg dict
    in
        ( Model newCounter state_
        , request
            { func = "eth.getBlockNumber"
            , args = []
            , id = counter
            }
        )


decodeBlockNumber : Value -> Result String Int
decodeBlockNumber blockNumber =
    case decodeValue string blockNumber of
        Ok blockNumber ->
            String.toInt blockNumber

        Err error ->
            Err error


getBlock : Model msg -> (Value -> msg) -> Int -> ( Model msg, Cmd msg )
getBlock (Model counter dict) msg blockNumber =
    let
        newCounter =
            counter + 1

        state_ =
            Dict.insert counter msg dict
    in
        ( Model newCounter state_
        , request
            { func = "eth.getBlock"
            , args = [ toString blockNumber ]
            , id = counter
            }
        )


bigIntDecoder : Decoder BigInt
bigIntDecoder =
    let
        convert stringBigInt =
            case BigInt.fromString stringBigInt of
                Just bigint ->
                    Decode.succeed bigint

                Nothing ->
                    Decode.fail "Error decoding BigInt"
    in
        string |> Decode.andThen convert


blockDecoder : Decoder Block
blockDecoder =
    decode Block
        |> required "author" string
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
        |> required "sealFields" string
        |> required "sha3Uncles" string
        |> required "size" int
        |> required "stateRoot" string
        |> required "timestamp" int
        |> required "totalDifficulty" bigIntDecoder
        |> required "transactions" (list string)
        |> required "transactionsRoot" string
        |> required "uncles" (list string)


decodeBlock : Value -> Result String Block
decodeBlock block =
    decodeValue blockDecoder block


port request : Request -> Cmd msg


port response : (Response -> msg) -> Sub msg
