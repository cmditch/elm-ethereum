module Web3
    exposing
        ( Error(..)
        , toTask
        )

import Native.Web3
import Task exposing (Task)
import Web3.Internal exposing (Request)
import Process
import Time


type Error
    = Error String
    | BadPayload String
    | NoWallet


type alias Retry =
    { attempts : Int
    , sleep : Float
    }


toTask : Request a -> Task Error a
toTask request =
    Native.Web3.toTask request



{-
   Mad props to Nick Miller for this retry function
-}


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
                        Process.sleep (sleep * Time.millisecond)
                            |> Task.andThen (\_ -> retry (Retry remaining sleep) web3Task)
                    else
                        Task.fail x
                )
