module Web3.Net exposing (getListening, getPeerCount)

{-| Net allows one to get p2p status information. [Web3
documentation on Version](https://github.com/ethereum/wiki/wiki/JavaScript-API#web3net).


# Net

@docs getListening, getPeerCount

-}

import Web3 exposing (Error)
import Web3.Types exposing (CallType(..))
import Web3.Decoders exposing (expectInt, expectBool)
import Json.Encode as Encode
import Task exposing (Task)


-- NET


{-| Returns True if the node is actively listening for network connections, otherwise False.

    Web3.Net.getListening  -- Ok True

-}
getListening : Task Error Bool
getListening =
    Web3.toTask
        { func = "net.getListening"
        , args = Encode.list []
        , expect = expectBool
        , callType = Async
        }


{-| Returns the number of connected peers.

    Web3.Net.getPeerCount -- Ok 42

-}
getPeerCount : Task Error Int
getPeerCount =
    Web3.toTask
        { func = "net.getPeerCount"
        , args = Encode.list []
        , expect = expectInt
        , callType = Async
        }
