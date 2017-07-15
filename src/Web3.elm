module Web3
    exposing
        ( Request
        , Response
        )

import Native.Web3


type alias Request =
    { func : String
    , args : List String
    }


type alias Response =
    String
