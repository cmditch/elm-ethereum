module Web3
    exposing
        ( Retry
        , reset
        , toChecksumAddress
        , toTask
        , toResult
        , setOrGet
        , getEvent
        , retry
        )

{-| Version allows one to check the various library, protocol, & network versions one is interacting with. [Web3
documentation on Version](https://github.com/ethereum/wiki/wiki/JavaScript-API#web3versionapi).


# Web3

@docs isConnected


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


{-| Check to see if a connection to a node exists

    Web3.isConnected  == Ok True

-}
isConnected : Task Error Bool
isConnected =
    toTask
        { func = "isConnected"
        , args = Encode.list []
        , expect = expectBool
        }



-- TODO Make this it's own native function. Perhaps have it clear out the eventRegister obect as well,
--      unless that will conflict with Contract.stopWatching task.


reset : Bool -> Task Error ()
reset keepIsSyncing =
    Native.Web3.reset (Encode.bool keepIsSyncing)


sha3 : String -> Result Error Keccak256
sha3 val =
    toResult
        { func = "sha3"
        , args = Encode.list [ Encode.string val ]
        , expect = expectJson keccakDecoder
        }


type Sha3Encoding
    = HexEncoded


sha3Encoded : Sha3Encoding -> String -> Result Error Keccak256
sha3Encoded encodeType val =
    let
        encoding =
            case encodeType of
                HexEncoded ->
                    Encode.string "hex"
    in
        toResult
            { func = "sha3"
            , args = Encode.list [ Encode.string val, Encode.object [ ( "encoding", encoding ) ] ]
            , expect = expectJson keccakDecoder
            }


toHex : String -> Result Error Hex
toHex val =
    toResult
        { func = "toHex"
        , args = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        }


toAscii : Hex -> Result Error String
toAscii (Hex val) =
    toResult
        { func = "toAscii"
        , args = Encode.list [ Encode.string val ]
        , expect = expectString
        }


fromAscii : String -> Result Error Hex
fromAscii val =
    fromAsciiPadded 0 val


fromAsciiPadded : Int -> String -> Result Error Hex
fromAsciiPadded padding val =
    toResult
        { func = "fromAscii"
        , args = Encode.list [ Encode.string val, Encode.int padding ]
        , expect = expectJson hexDecoder
        }


toDecimal : Hex -> Result Error Int
toDecimal (Hex hex) =
    toResult
        { func = "toDecimal"
        , args = Encode.list [ Encode.string hex ]
        , expect = expectInt
        }


fromDecimal : Int -> Result Error Hex
fromDecimal decimal =
    toResult
        { func = "fromDecimal"
        , args = Encode.list [ Encode.int decimal ]
        , expect = expectJson hexDecoder
        }


isAddress : Address -> Result Error Bool
isAddress (Address address) =
    toResult
        { func = "isAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBool
        }


isChecksumAddress : Address -> Result Error Bool
isChecksumAddress (Address address) =
    toResult
        { func = "isChecksumAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBool
        }


toChecksumAddress : Address -> Result Error Address
toChecksumAddress (Address address) =
    toResult
        { func = "toChecksumAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectJson addressDecoder
        }



{-
   TODO
   fromWei : EthUnit -> BigInt -> String

   toWei : EthUnit -> String -> Maybe BigInt

   bigIntToWei : EthUnit -> BigInt -> BigInt

-}
-- CORE


toTask : Request a -> Task Error a
toTask =
    Native.Web3.toTask


toResult : Request a -> Result Error a
toResult =
    Native.Web3.toResult


setOrGet : CallType -> Request a -> Task Error a
setOrGet callType request =
    Native.Web3.setOrGet callType request


getEvent : Request a -> Task Error a
getEvent =
    Native.Web3.getEvent



-- POLLING
{-
   Mad props to Nick Miller for this retry function
              The MIRTCH Function
   "Matrix Inception Recursive Task Chaining" Function
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
