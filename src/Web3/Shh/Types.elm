module Web3.Shh.Types exposing (..)

import Web3.Internal.Types exposing (WhisperId)

type WhisperId
    = Internal.WhisperId


type alias Post =
    { from : Maybe String
    , to : Maybe String
    , topics : List String
    , payload : String
    , priority : Int
    , ttl : Int
    }
