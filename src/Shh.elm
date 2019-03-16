module Shh exposing
    ( Post, post
    , WhisperId, newIdentity, whisperIdToString, toWhisperId, version
    )

{-| Whipser API (Use at your own risk! Work in progress)


# Whisper messaging

@docs Post, post


# Whisper Id's

@docs WhisperId, newIdentity, whisperIdToString, toWhisperId, version

-}

import Eth.Decode as Decode
import Eth.Encode as Encode exposing (listOfMaybesToVal)
import Eth.RPC as RPC
import Eth.Types exposing (..)
import Eth.Utils exposing (..)
import Http
import Internal.Types as Internal
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Task exposing (Task)



-- Whisper Messaging


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
post : HttpProvider -> Post -> Task Http.Error Bool
post ethNode post_ =
    RPC.toTask
        { url = ethNode
        , method = "shh_post"
        , params = [ encodePost post_ ]
        , decoder = Decode.bool
        }



-- Whisper Id's


{-| -}
type alias WhisperId =
    Internal.WhisperId


{-| -}
newIdentity : HttpProvider -> Task Http.Error WhisperId
newIdentity ethNode =
    RPC.toTask
        { url = ethNode
        , method = "shh_newIdentity"
        , params = []
        , decoder = Decode.resultToDecoder toWhisperId
        }


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


{-| -}
version : HttpProvider -> Task Http.Error Int
version ethNode =
    RPC.toTask
        { url = ethNode
        , method = "shh_version"
        , params = []
        , decoder = Decode.stringInt
        }



-- Internal Decoder/Encoder


encodePost : Post -> Value
encodePost { to, from, topics, payload, priority, ttl } =
    listOfMaybesToVal
        [ ( "to", Maybe.map Encode.string to )
        , ( "from", Maybe.map Encode.string from )
        , ( "topics", Just (Encode.list Encode.string topics) )
        , ( "payload", Maybe.map Encode.string (Just payload) )
        , ( "priority", Maybe.map Encode.hexInt (Just priority) )
        , ( "ttl", Maybe.map Encode.hexInt (Just ttl) )
        ]
