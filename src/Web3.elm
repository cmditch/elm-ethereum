module Web3
    exposing
        ( Error(..)
        , toTask
        , send
        )

{-| Web3
-}

import Native.Web3
import Task exposing (Task)
import Web3.Internal exposing (Request)


type Error
    = Error String
    | BadPayload String


toTask : Request a -> Task Error a
toTask request =
    Native.Web3.toTask request


send : (Result Error a -> msg) -> Request a -> Cmd msg
send msg request =
    Task.attempt msg (toTask request)
