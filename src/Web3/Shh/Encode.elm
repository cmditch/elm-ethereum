module Web3.Shh.Encode exposing (post)

{-| Whisper Encoders

@docs post

-}

import Json.Encode exposing (Value, int, list, string, object, null)
import Web3.Encode exposing (hexInt)
import Web3.Shh.Types exposing (Post)
import Web3.Internal.Utils exposing (listOfMaybesToVal)


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
