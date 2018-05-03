module Web3.Shh
    exposing
        ( version
        , post
        , newIdentity
        )

{-| Whipser API

@docs version, post, newIdentity

-}

import Json.Decode as Decode
import Http
import Task exposing (Task)
import Web3.Decode as Decode
import Web3.Types exposing (..)
import Web3.Shh.Types exposing (Post, WhisperId)
import Web3.Shh.Encode as Encode
import Web3.Shh.Decode as Decode
import Web3.JsonRPC as RPC


{-| -}
version : HttpProvider -> Task Http.Error Int
version ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "shh_version"
        , params = []
        , decoder = Decode.stringInt
        }


{-| -}
post : HttpProvider -> Post -> Task Http.Error Bool
post ethNode post =
    RPC.buildRequest
        { url = ethNode
        , method = "shh_post"
        , params = [ Encode.post post ]
        , decoder = Decode.bool
        }


{-| -}
newIdentity : HttpProvider -> Task Http.Error WhisperId
newIdentity ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "shh_newIdentity"
        , params = []
        , decoder = Decode.whisperId
        }
