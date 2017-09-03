module Web3.Utils
    exposing
        ( sha3
        , toHex
        , hexToAscii
        , hexToNumber
        , asciiToHex
        , numberToHex
        , isAddress
        , toChecksumAddress
        , checkAddressChecksum
        , fromWei
        , toWei
        )

import BigInt exposing (BigInt)
import Task exposing (Task)
import Json.Encode as Encode
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (encodeBytes)
import Regex
import Web3 exposing (toTask)


-- UTIL


randomHex : Int -> Task Error Hex
randomHex size =
    toTask
        { method = "utils.randomHex"
        , params = Encode.list [ Encode.int size ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


sha3 : String -> Task Error Hex
sha3 val =
    toTask
        { method = "utils.sha3"
        , params = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }



{- Need to implement this Possibly in Web3.Eth.Solidity Module

   soliditySha3 : List SoldiityTypes -> Task Error Sha3
   soliditySha3 solidityTypes =
       toTask
           { method = "utils.soliditySha3"
           , params = encodeSolidityTypes solidityTypes
           , expect = expectJson keccakDecoder
           , callType = Sync
           }

-}


isHex : String -> Task Error Bool
isHex val =
    toTask
        { method = "utils.isHex"
        , params = Encode.list [ Encode.string val ]
        , expect = expectBool
        , callType = Sync
        }


isAddress : Address -> Task Error Bool
isAddress (Address address) =
    toTask
        { method = "utils.isAddress"
        , params = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        }


toChecksumAddress : Address -> Task Error Address
toChecksumAddress (Address address) =
    toTask
        { method = "utils.toChecksumAddress"
        , params = Encode.list [ Encode.string address ]
        , expect = expectJson addressDecoder
        , callType = Sync
        }


checkAddressChecksum : Address -> Task Error Bool
checkAddressChecksum (Address address) =
    toTask
        { method = "utils.isAddress"
        , params = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        }


toHex : String -> Task Error Hex
toHex val =
    toTask
        { method = "utils.toHex"
        , params = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


hexToNumberString : Hex -> Task Error String
hexToNumberString (Hex val) =
    toTask
        { method = "utils.hexToNumberString"
        , params = Encode.list [ Encode.string val ]
        , expect = expectString
        , callType = Sync
        }


hexToNumber : Hex -> Task Error Int
hexToNumber (Hex val) =
    toTask
        { method = "utils.hexToNumber"
        , params = Encode.list [ Encode.string val ]
        , expect = expectInt
        , callType = Sync
        }


numberToHex : Int -> Task Error Hex
numberToHex number =
    toTask
        { method = "utils.numberToHex"
        , params = Encode.list [ Encode.string <| toString number ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


bigIntToHex : BigInt -> Task Error Hex
bigIntToHex number =
    toTask
        { method = "utils.numberToHex"
        , params = Encode.list [ Encode.string <| BigInt.toString number ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


hexToUtf8 : Hex -> Task Error String
hexToUtf8 (Hex val) =
    toTask
        { method = "utils.hexToUtf8"
        , params = Encode.list [ Encode.string val ]
        , expect = expectString
        , callType = Sync
        }


utf8ToHex : String -> Task Error Hex
utf8ToHex val =
    toTask
        { method = "utils.utf8ToHex"
        , params = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


hexToAscii : Hex -> Task Error String
hexToAscii (Hex val) =
    toTask
        { method = "utils.hexToAscii"
        , params =
            Encode.list [ Encode.string val ]
            -- TODO See if toAsciiDecoder is still needed
        , expect = expectJson toAsciiDecoder
        , callType = Sync
        }


asciiToHex : String -> Task Error Hex
asciiToHex val =
    toTask
        { method = "utils.asciiToHex"
        , params = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


hexToBytes : Hex -> Task Error Bytes
hexToBytes (Hex hex) =
    toTask
        { method = "utils.hexToBytes"
        , params = Encode.list [ Encode.string hex ]
        , expect = expectJson bytesDecoder
        , callType = Sync
        }


bytesToHex : Bytes -> Task Error Hex
bytesToHex byteArray =
    toTask
        { method = "utils.bytesToHex"
        , params = Encode.list [ encodeBytes byteArray ]
        , expect = expectJson hexDecoder
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
                    Err "There was an error calculating toWei result. However, the fault is not yours; please report this bug on github."
    else
        Err "Malformed number string passed to `toWei` methodtion."


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


bigIntToWei : EthUnit -> BigInt -> BigInt
bigIntToWei unit amount =
    List.repeat (decimalShift unit) (BigInt.fromInt 10)
        |> List.foldl BigInt.mul (BigInt.fromInt 1)
        |> BigInt.mul amount



--unitMap TODO Is this needed?


leftPadHex : Int -> Hex -> Hex
leftPadHex =
    leftPadHexCustom '0'


leftPadHexCustom : Char -> Int -> Hex -> Hex
leftPadHexCustom char amount (Hex hex) =
    let
        deconstruct hexString =
            ( String.left 2 hexString, String.dropLeft 2 hexString )

        padAndReconstruct ( zeroX, data ) =
            zeroX ++ String.padLeft amount char data
    in
        deconstruct hex
            |> padAndReconstruct
            |> Hex


rightPadHex : Int -> Hex -> Hex
rightPadHex =
    rightPadHexCustom '0'


rightPadHexCustom : Char -> Int -> Hex -> Hex
rightPadHexCustom char amount (Hex hex) =
    String.padRight amount char hex
        |> Hex



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
