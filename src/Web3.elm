module Web3
    exposing
        ( version
        , retry
        , retryThrice
        , delayExecution
        , Retry
        )

{-| Version allows one to check the various library, protocol, & network versions one is interacting with. [Web3
documentation on Version](https://github.com/ethereum/wiki/wiki/JavaScript-API#web3versionapi).


# Web3

@docs version, retry, retryThrice, delayExecution, Retry

-}

import Web3.Internal as Internal exposing (CallType(..))
import Time
import Process
import Task exposing (Task)
import Json.Encode as Encode
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)


-- WEB3


{-| Get the version of web3.js library used

    Web3.version == "1.0.0-beta.18"

-}
version : Task Error String
version =
    Internal.toTask
        { method = "version"
        , params = Encode.list []
        , expect = expectString
        , callType = Getter
        , applyScope = Nothing
        }



{-
   Mad props to Nick Miller for this retry function
              The MIRTCH function
   "Matrix Inception Recursive Task Chaining" function
-}


{-| -}
type alias Retry =
    { attempts : Int
    , sleep : Float
    }


{-| -}
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


{-| -}
delayExecution : Task x a -> Task x a
delayExecution task =
    Process.sleep 50 |> Task.andThen (\_ -> task)


{-| -}
retryThrice : Task Error a -> Task Error a
retryThrice =
    retry { sleep = 1, attempts = 3 }
