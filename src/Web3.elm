module Web3
    exposing
        ( Error(..)
        , Retry
        , toTask
        , watchEvent
        , retry
        )

{-| Version allows one to check the various library, protocol, & network versions one is interacting with. [Web3
documentation on Version](https://github.com/ethereum/wiki/wiki/JavaScript-API#web3versionapi).


# Web3

@docs isConnected


# Core

@docs Error

-}

import Native.Web3
import Web3.Internal exposing (Request, EventRequest)
import Web3.Decoders exposing (expectString, expectInt, expectBool)
import Web3.Types exposing (CallType(..), Keccak256, Hex)
import Web3.Eth.Types exposing (..)
import Json.Encode as Encode
import Task exposing (Task)
import Process
import Time


-- WEB3


{-| Check to see if a connection to a node exists

    Web3.isConnected  == Ok True

-}
isConnected : Task Error Bool
isConnected =
    toTask
        { func = "isConnected"
        , args = Encode.list []
        , expect = expectBool
        , callType = Async
        }



-- TODO Make this it's own native function. Perhaps have it clear out the eventRegister obect as well,
--      unless that will conflict with Contract.stopWatching task.


reset : Bool -> Task Error Bool
reset keepIsSyncing =
    Native.Web3.reset keepIsSyncing


sha3 : String -> Task Error Keccak256
sha3 val =
    toTask
        { func = "sha3"
        , args = Encode.list [ Encode.string val ]
        , expect = expectString
        , callType = Sync
        }


type Sha3Encoding
    = HexEncoded


sha3Encoded : Sha3Encoding -> String -> Task Error Keccak256
sha3Encoded encodeType val =
    let
        encoding =
            case encodeType of
                HexEncoded ->
                    Encode.string "hex"
    in
        toTask
            { func = "sha3"
            , args = Encode.list [ Encode.string val, Encode.object [ ( "encoding", encoding ) ] ]
            , expect = expectString
            , callType = Sync
            }


toHex : String -> Task Error Hex
toHex val =
    toTask
        { func = "toHex"
        , args = Encode.list [ Encode.string val ]
        , expect = expectString
        , callType = Sync
        }


toAscii : Hex -> Task Error String
toAscii val =
    toTask
        { func = "toAscii"
        , args = Encode.list [ Encode.string val ]
        , expect = expectString
        , callType = Sync
        }


fromAscii : String -> Task Error Hex
fromAscii val =
    fromAsciiPadded 0 val


fromAsciiPadded : Int -> String -> Task Error Hex
fromAsciiPadded padding val =
    toTask
        { func = "fromAscii"
        , args = Encode.list [ Encode.string val, Encode.int padding ]
        , expect = expectString
        , callType = Sync
        }


toDecimal : Hex -> Task Error Int
toDecimal hex =
    toTask
        { func = "toDecimal"
        , args = Encode.list [ Encode.string hex ]
        , expect = expectInt
        , callType = Sync
        }


fromDecimal : Int -> Task Error Hex
fromDecimal decimal =
    toTask
        { func = "fromDecimal"
        , args = Encode.list [ Encode.int decimal ]
        , expect = expectString
        , callType = Sync
        }


isAddress : Address -> Task Error Bool
isAddress address =
    toTask
        { func = "isAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        }


isChecksumAddress : ChecksumAddress -> Task Error Bool
isChecksumAddress address =
    toTask
        { func = "isChecksumAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        }


toChecksumAddress : Address -> Task Error ChecksumAddress
toChecksumAddress address =
    toTask
        { func = "toChecksumAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectString
        , callType = Sync
        }



-- fromWei : EthUnit -> BigInt -> BigInt
-- toWei : EthUnit -> BigInt -> BigInt
-- CORE


type Error
    = Error String
    | BadPayload String
    | NoWallet


toTask : Request a -> Task Error a
toTask request =
    Native.Web3.toTask request


watchEvent : EventRequest -> Task Error ()
watchEvent eventRequest =
    Native.Web3.watchEvent eventRequest


stopEvent : Task Error a
stopEvent =
    Native.Web3.stopEvent



-- POLLING


type alias Retry =
    { attempts : Int
    , sleep : Float
    }



{-
   Mad props to Nick Miller for this retry function
              The MIRTCH Function
   "Matrix Inception Recursive Task Chaining" Function
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
                        Process.sleep (sleep * Time.second)
                            |> Task.andThen (\_ -> retry (Retry remaining sleep) web3Task)
                    else
                        Task.fail x
                )
