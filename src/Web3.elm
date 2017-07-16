module Web3
    exposing
        ( Request
        , Error(..)
        , toTask
        , send
        )

{-| Web3
-}

import Native.Web3
import Task exposing (Task)
import Web3.Internal


{-| Request
Represents a web3 request expecting a response of type `a`.
Masks the internal request structure.
-}
type alias Request a =
    Web3.Internal.Request a


type Error
    = Error String
    | BadPayload String


toTask : Request a -> Task Error a
toTask (Web3.Internal.Request request) =
    Native.Web3.toTask request


send : (Result Error a -> msg) -> Request a -> Cmd msg
send msg request =
    Task.attempt msg (toTask request)
