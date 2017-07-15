module Web3.Eth
    exposing
        ( getBlockNumber
        , getBlock
        )

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Block)
import Web3.Eth.Decoders exposing (blockDecoder)
import Web3.Internal exposing (expectInt, expectJson)
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


getBlock : (Result Error Block -> msg) -> Int -> Cmd msg
getBlock msg blockNum =
    Task.attempt msg
        (Native.Web3.request
            { func = "eth.getBlock"
            , args = list [ int blockNum ]
            , expect = expectJson blockDecoder
            }
        )
