module Web3
    exposing
        ( version
        , Retry
        , reset
        , toTask
        , setOrGet
        , getEvent
        , retry
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
import Web3.Internal exposing (Request, EventRequest, GetDataRequest)


-- WEB3


{-| Get the version of web3.js library used

    Web3.version == "1.0.0-beta.18"

-}
version : Task Error String
version =
    setOrGet
        { method = "version"
        , params = Encode.list []
        , expect = expectString
        , callType = Getter
        }



-- TODO Make this it's own native function. Perhaps have it clear out the eventRegister obect as well,
--      unless that will conflict with Contract.stopWatching task.


reset : Bool -> Task Error ()
reset keepIsSyncing =
    Native.Web3.reset (Encode.bool keepIsSyncing)


toTask : Request a -> Task Error a
toTask =
    Native.Web3.toTask


setOrGet : Request a -> Task Error a
setOrGet =
    Native.Web3.setOrGet


getEvent : Request a -> Task Error a
getEvent =
    Native.Web3.getEvent



-- POLLING
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
