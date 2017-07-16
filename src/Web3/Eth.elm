module Web3.Eth
    exposing
        ( getBlockNumber
        , getBlock
        )

{-| Web3.Eth
-}

import Web3 exposing (Error, Request)
import Web3.Eth.Types exposing (Block)
import Web3.Eth.Decoders exposing (blockDecoder)
import Web3.Internal as Internal exposing (Expect, expectInt, expectJson)
import Json.Encode as Encode
import Native.Web3
import Task


request :
    { func : String
    , args : Encode.Value
    , expect : Expect a
    }
    -> Request a
request =
    Internal.Request


getBlockNumber : Request Int
getBlockNumber =
    request
        { func = "eth.getBlockNumber"
        , args = Encode.list []
        , expect = expectInt
        }


getBlock : Int -> Request Block
getBlock blockNum =
    request
        { func = "eth.getBlock"
        , args = Encode.list [ Encode.int blockNum ]
        , expect = expectJson blockDecoder
        }
