module Web3
    exposing
        ( version
        , toTask
        , retry
        , retryThrice
        , Retry
        )

{-| Version allows one to check the various library, protocol, & network versions one is interacting with. [Web3
documentation on Version](https://github.com/ethereum/wiki/wiki/JavaScript-API#web3versionapi).


# Web3

@docs version


# Core

@docs Error

-}

import Time
import Process
import Task exposing (Task)
import Json.Encode as Encode
import Native.Web3
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.Internal exposing (Request, EventRequest)


-- WEB3


{-| Get the version of web3.js library used

    Web3.version == "1.0.0-beta.18"

-}
version : Task Error String
version =
    toTask
        { method = "version"
        , params = Encode.list []
        , expect = expectString
        , callType = Getter
        , applyScope = Nothing
        }


{-|

    Magic happens here
-}
toTask : Request a -> Task Error a
toTask request =
    Native.Web3.toTask (evalHelper request) request


evalHelper : Request a -> String
evalHelper request =
    let
        applyScope =
            case request.applyScope of
                Just scope ->
                    scope

                Nothing ->
                    "null"

        callType =
            case request.callType of
                Async ->
                    ".apply(" ++ applyScope ++ ", request.params.concat(web3Callback))"

                Sync ->
                    ".apply(" ++ applyScope ++ ", request.params)"

                CustomSync _ ->
                    ".apply(" ++ applyScope ++ ", request.params)"

                Getter ->
                    ""
    in
        "web3."
            ++ request.method
            ++ callType



{-
   Mad props to Nick Miller for this retry function
              The MIRTCH function
   "Matrix Inception Recursive Task Chaining" function
-}


type alias Retry =
    { attempts : Int
    , sleep : Float
    }


retry : Retry -> Task Error a -> Task Error a
retry { attempts, sleep } web3Task =
    let
        remaining =
            attempts - 1
    in
        web3Task
            |> Task.onError
                (\x ->
                    if remaining > 0 then
                        Process.sleep (sleep * Time.second)
                            |> Task.andThen (\_ -> retry (Retry remaining sleep) web3Task)
                    else
                        Task.fail x
                )


retryThrice : Task Error a -> Task Error a
retryThrice =
    retry { sleep = 1, attempts = 3 }
