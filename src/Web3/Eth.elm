module Web3.Eth
    exposing
        ( getBlockNumber
        , getBlock
        )

{-| Web3.Eth
-}

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Block)
import Web3.Eth.Decoders exposing (blockDecoder)
import Web3.Internal as Internal exposing (Expect, Request, expectInt, expectJson)
import Json.Encode as Encode
import Task exposing (Task)


getBlockNumber : Task Error Int
getBlockNumber =
    { func = "eth.getBlockNumber"
    , args = Encode.list []
    , expect = expectInt
    }
        |> Web3.toTask


getBlock : Int -> Task Error Block
getBlock blockNum =
    { func = "eth.getBlock"
    , args = Encode.list [ Encode.int blockNum ]
    , expect = expectJson blockDecoder
    }
        |> Web3.toTask
