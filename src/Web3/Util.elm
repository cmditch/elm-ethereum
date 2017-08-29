module Web3.Util
    exposing
        ( sha3
        , toHex
        , toAscii
        , fromAscii
        , toDecimal
        , fromDecimal
        , isAddress
        , isChecksumAddress
        , toChecksumAddress
        , fromWei
        , toWei
        )

import BigInt exposing (BigInt)
import Task exposing (Task)
import Json.Encode as Encode
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Regex
import Web3 exposing (toTask)


-- UTIL


sha3 : String -> Task Error Keccak256
sha3 val =
    toTask
        { func = "sha3"
        , args = Encode.list [ Encode.string val ]
        , expect = expectJson keccakDecoder
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
            , expect = expectJson keccakDecoder
            , callType = Sync
            }


toHex : String -> Task Error Hex
toHex val =
    toTask
        { func = "toHex"
        , args = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


toAscii : Hex -> Task Error String
toAscii (Hex val) =
    toTask
        { func = "toAscii"
        , args = Encode.list [ Encode.string val ]
        , expect = expectJson toAsciiDecoder
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
        , expect = expectJson hexDecoder
        , callType = Sync
        }


toDecimal : Hex -> Task Error Int
toDecimal (Hex hex) =
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
        , expect = expectJson hexDecoder
        , callType = Sync
        }


isAddress : Address -> Task Error Bool
isAddress (Address address) =
    toTask
        { func = "isAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        }


isChecksumAddress : Address -> Task Error Bool
isChecksumAddress (Address address) =
    toTask
        { func = "isChecksumAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        }


toChecksumAddress : Address -> Task Error Address
toChecksumAddress (Address address) =
    toTask
        { func = "toChecksumAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectJson addressDecoder
        , callType = Sync
        }


toWei : EthUnit -> String -> Result String BigInt
toWei unit amount =
    -- check to make sure input string is formatted correctly, should never error in here.
    if Regex.contains (Regex.regex "^\\d*\\.?\\d+$") amount then
        let
            decimalPoints =
                decimalShift unit

            formatMantissa =
                String.slice 0 decimalPoints >> String.padRight decimalPoints '0'

            finalResult =
                case (String.split "." amount) of
                    [ a, b ] ->
                        a ++ (formatMantissa b)

                    [ a ] ->
                        a ++ (formatMantissa "")

                    _ ->
                        "ImpossibleError"
        in
            case (BigInt.fromString finalResult) of
                Just result ->
                    Ok result

                Nothing ->
                    Err "There was an error calculating the result. However, the fault is not yours; please report this bug on github."
    else
        Err "Malformed number string passed to `toWei` function."


fromWei : EthUnit -> BigInt -> String
fromWei unit amount =
    let
        decimalIndex =
            decimalShift unit

        -- There are under 10^27 wei in existance (so we safe for the next couple of malenium of mining).
        amountStr =
            BigInt.toString amount |> String.padLeft 27 '0'

        result =
            (String.left (27 - decimalIndex) amountStr)
                ++ "."
                ++ (String.right decimalIndex amountStr)
    in
        result
            |> Regex.replace Regex.All
                (Regex.regex "(^0*(?=0\\.|[1-9]))|(\\.?0*$)")
                (\i -> "")



--Private


decimalShift : EthUnit -> Int
decimalShift unit =
    case unit of
        Wei ->
            0

        Kwei ->
            3

        Ada ->
            3

        Femtoether ->
            3

        Mwei ->
            6

        Babbage ->
            6

        Picoether ->
            6

        Gwei ->
            9

        Shannon ->
            9

        Nanoether ->
            9

        Nano ->
            9

        Szabo ->
            12

        Microether ->
            12

        Micro ->
            12

        Finney ->
            15

        Milliether ->
            15

        Milli ->
            15

        Ether ->
            18

        Kether ->
            21

        Grand ->
            21

        Einstein ->
            21

        Mether ->
            24

        Gether ->
            27

        Tether ->
            30
