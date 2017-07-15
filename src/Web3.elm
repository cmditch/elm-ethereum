module Web3
    exposing
        ( Request
        , Error(..)
        )

import Native.Web3
import Web3.Internal exposing (Expect)


type alias Request a =
    { func : String
    , args : List String
    , expect : Expect a
    }


type Error
    = Error String
