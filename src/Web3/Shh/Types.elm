module Web3.Shh.Types
    exposing
        ( WhisperId
        , Post
        )

{-| Whisper Types

@docs WhisperId, Post

-}

import Web3.Internal.Types as Internal


{-| -}
type alias WhisperId =
    Internal.WhisperId


{-| -}
type alias Post =
    { from : Maybe String
    , to : Maybe String
    , topics : List String
    , payload : String
    , priority : Int
    , ttl : Int
    }
