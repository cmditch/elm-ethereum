module Web3.Eth
    exposing
        ( decodeBlock
        , getBlockNumber
        , getBlock
        , decodeBlockNumber
        )

import Web3 exposing (Model(..))
import Web3.Eth.Types exposing (Block)
import Web3.Eth.Decoders exposing (blockDecoder)
import Json.Decode as Decode exposing (string, decodeString)
import Dict


getBlockNumber : Model msg -> (String -> msg) -> ( Model msg, Cmd msg )
getBlockNumber (Model counter dict) msg =
    let
        newCounter =
            counter + 1

        state_ =
            Dict.insert counter msg dict
    in
        ( Model newCounter state_
        , Web3.request
            { func = "eth.getBlockNumber"
            , args = []
            , id = counter
            }
        )


decodeBlockNumber : String -> Result String Int
decodeBlockNumber blockNumber =
    String.toInt blockNumber


getBlock : Model msg -> (String -> msg) -> Int -> ( Model msg, Cmd msg )
getBlock (Model counter dict) msg blockNumber =
    let
        newCounter =
            counter + 1

        state_ =
            Dict.insert counter msg dict
    in
        ( Model newCounter state_
        , Web3.request
            { func = "eth.getBlock"
            , args = [ toString blockNumber ]
            , id = counter
            }
        )


decodeBlock : String -> Result String Block
decodeBlock block =
    Decode.decodeString blockDecoder block
