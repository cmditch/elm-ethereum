module Web3.Eth
    exposing
        ( getBlockNumber
        , decodeBlockNumber
        )

import Web3.Eth.Types exposing (Block)
import Web3.Eth.Decoders exposing (blockDecoder)
import Json.Decode as Decode exposing (string, decodeString)
import Json.Encode exposing (list, int)
import Native.Web3
import Task


getBlockNumber : (String -> msg) -> Cmd msg
getBlockNumber msg =
    Task.perform msg
        (Native.Web3.request
            { func = "eth.getBlockNumber"
            , args = list []
            }
        )


decodeBlockNumber : String -> Result String Int
decodeBlockNumber blockNumber =
    String.toInt blockNumber
