module Web3
    exposing
        ( Error(..)
        , toTask
        )

import Native.Web3
import Task exposing (Task)
import Web3.Internal exposing (Request)


type Error
    = Error String
    | BadPayload String
    | NoWallet


toTask : Request a -> Task Error a
toTask request =
    Native.Web3.toTask request
