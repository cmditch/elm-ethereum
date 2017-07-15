module Web3.Eth
    exposing
        ( getBlockNumber
        , decodeBlockNumber
        , Error(..)
        )

import Web3.Eth.Types exposing (Block)
import Web3.Eth.Decoders exposing (blockDecoder)
import Json.Decode as Decode exposing (string, decodeString)
import Json.Encode exposing (list, int)
import Native.Web3
import Task


type Error
    = Error String


getBlockNumber : (Result Error String -> msg) -> Cmd msg
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



-- TODO: Thread an expected return type and decoder through to handle more complex data types.
-- See elm-lang/elm-http for inspiration
-- getBlock : Int -> (Block -> msg) -> Cmd msg
