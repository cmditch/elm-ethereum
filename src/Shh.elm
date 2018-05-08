module Shh
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
import Eth.Decode as Decode
import Eth.Types exposing (..)
import Eth.JsonRPC as RPC
import Shh.Types exposing (Post, WhisperId)
import Shh.Encode as Encode
import Shh.Decode as Decode


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
