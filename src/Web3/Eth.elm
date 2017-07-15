module Web3.Eth
    exposing
        ( getBlockNumber
        )

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Block)
import Web3.Eth.Decoders exposing (blockDecoder)
import Web3.Internal exposing (expectInt)
import Json.Decode as Decode exposing (string, decodeString)
import Json.Encode exposing (list, int)
import Native.Web3
import Task


getBlockNumber : (Result Error Int -> msg) -> Cmd msg
getBlockNumber msg =
    Task.attempt msg
        (Native.Web3.request
            { func = "eth.getBlockNumber"
            , args = list []
            , expect = expectInt
            }
        )



-- TODO: Thread an expected return type and decoder through to handle more complex data types.
-- See elm-lang/elm-http for inspiration
-- getBlock : Int -> (Block -> msg) -> Cmd msg
