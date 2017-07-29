module Web3.Version exposing (api, getNode, getNetwork, getEthereum)

{-| Version allows one to check the various library, protocol, & network versions one is interacting with. [Web3
documentation on Version](https://github.com/ethereum/wiki/wiki/JavaScript-API#web3versionapi).


# Versions

@docs api, getNode, getNetwork, getEthereum

-}

import Web3 exposing (Error)
import Web3.Types exposing (Hex, CallType(..))
import Web3.Decoders exposing (expectString)
import Json.Encode as Encode
import Task exposing (Task)


-- VERSIONS


{-| The ethereum js api version

    Web3.Version.api == Ok "0.19.0"

-}
api : Task Error String
api =
    Web3.toTask
        { func = "version.api"
        , args = Encode.list []
        , expect = expectString
        , callType = Sync
        }


{-| The client/node version

    Web3.Version.getNode == Ok "MetaMask/v3.9.2"

-}
getNode : Task Error String
getNode =
    Web3.toTask
        { func = "version.getNode"
        , args = Encode.list []
        , expect = expectString
        , callType = Async
        }


{-| The network protocol version.

    Web3.Version.getNetwork == Ok "3"

-}
getNetwork : Task Error String
getNetwork =
    Web3.toTask
        { func = "version.getNetwork"
        , args = Encode.list []
        , expect = expectString
        , callType = Async
        }


{-| The ethereum protocol version

    Web3.Version.getEthereum == Ok "0x3f"
    |> Task.andThen Web3.toDecimal
    -- 63

-}
getEthereum : Task Error Hex
getEthereum =
    Web3.toTask
        { func = "version.getEthereum"
        , args = Encode.list []
        , expect = expectString
        , callType = Async
        }



-- {-| The whisper protocol version. (Not available)
--     Web3.Version.api == Ok "20"
-- -}
-- getWhisper : Task Error String
-- getWhisper =
--     Web3.toTask
--         { func = "version.getWhisper"
--         , args = Encode.list []
--         , expect = expectString
--         , callType = Async
--         }
