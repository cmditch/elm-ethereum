module Shh
    exposing
        ( Post
        , version
        , post
        , newIdentity
        , WhisperId
        , whisperIdToString
        , toWhisperId
        )

{-| Whipser API

@docs Post

@docs version, post, newIdentity

@docs WhisperId, whisperIdToString, toWhisperId

-}

import Eth.Decode as Decode
import Eth.Encode as Encode
import Eth.Types exposing (..)
import Eth.Utils exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Http
import Internal.Types as Internal
import Internal.Utils exposing (listOfMaybesToVal)
import Task exposing (Task)
import Web3.JsonRPC as RPC


{-| -}
type alias Post =
    { from : Maybe String
    , to : Maybe String
    , topics : List String
    , payload : String
    , priority : Int
    , ttl : Int
    }


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
        , params = [ encodePost post ]
        , decoder = Decode.bool
        }


{-| -}
newIdentity : HttpProvider -> Task Http.Error WhisperId
newIdentity ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "shh_newIdentity"
        , params = []
        , decoder = Decode.resultToDecoder toWhisperId
        }


{-| -}
type alias WhisperId =
    Internal.WhisperId


{-| -}
whisperIdToString : WhisperId -> String
whisperIdToString (Internal.WhisperId str) =
    str


{-| -}
toWhisperId : String -> Result String WhisperId
toWhisperId str =
    case isHex str && String.length str == 122 of
        True ->
            Ok <| Internal.WhisperId str

        False ->
            Err <| "Couldn't convert " ++ str ++ "into whisper id"



-- Internal Decoder/Encoder


encodePost : Post -> Value
encodePost { to, from, topics, payload, priority, ttl } =
    listOfMaybesToVal
        [ ( "to", Maybe.map Encode.string to )
        , ( "from", Maybe.map Encode.string from )
        , ( "topics", Maybe.map Encode.list (Just <| List.map Encode.string topics) )
        , ( "payload", Maybe.map Encode.string (Just payload) )
        , ( "priority", Maybe.map Encode.hexInt (Just priority) )
        , ( "ttl", Maybe.map Encode.hexInt (Just ttl) )
        ]
