module Request.Status exposing (..)


type RemoteData e a
    = NotAsked
    | Loading
    | Failure e
    | Success a
