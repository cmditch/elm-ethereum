module Shh.Encode exposing (post)

{-| Whisper Encoders

@docs post

-}

import Json.Encode exposing (Value, int, list, string, object, null)
import Eth.Encode exposing (hexInt)
import Internal.Utils exposing (listOfMaybesToVal)
import Shh.Types exposing (Post)


{-| -}
post : Post -> Value
post { to, from, topics, payload, priority, ttl } =
    listOfMaybesToVal
        [ ( "to", Maybe.map string to )
        , ( "from", Maybe.map string from )
        , ( "topics", Maybe.map list (Just <| List.map string topics) )
        , ( "payload", Maybe.map string (Just payload) )
        , ( "priority", Maybe.map hexInt (Just priority) )
        , ( "ttl", Maybe.map hexInt (Just ttl) )
        ]
