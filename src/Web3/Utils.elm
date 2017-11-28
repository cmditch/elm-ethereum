module Web3.Utils
    exposing
        ( randomHex
        , sha3
        , isHex
        , isAddress
        , isChecksumAddress
        , toChecksumAddress
        , checkAddressChecksum
        , toHex
        , hexToNumberString
        , hexToNumber
        , numberToHex
        , bigIntToHex
        , hexToUtf8
        , utf8ToHex
        , hexToAscii
        , asciiToHex
        , hexToBytes
        , bytesToHex
        , fromWei
        , toWei
        , bigIntToWei
        , leftPadHex
        , rightPadHex
        , leftPadHexCustom
        , rightPadHexCustom
        )

{-| Web3.Utils contains various helper functions for working with addresses, hex, ascii, etc.
**Note:** See [here](https://web3js.readthedocs.io/en/1.0/web3-utils.html) for web3.js documentation.


# Addresses

@docs isAddress, toChecksumAddress, checkAddressChecksum


# Conversions

@docs fromWei, toWei, toHex, hexToNumberString, hexToNumber, numberToHex
@docs bigIntToHex, hexToUtf8, utf8ToHex, hexToAscii, asciiToHex, hexToBytes, bytesToHex, bigIntToWei


# Misc

@docs sha3, isHex, randomHex, leftPadHex, rightPadHex, leftPadHexCustom, rightPadHexCustom

-}

import BigInt exposing (BigInt)
import Bool.Extra exposing (all)
import Char
import Keccak exposing (ethereum_keccak_256)
import Task exposing (Task)
import Json.Encode as Encode
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (encodeBytes)
import Regex
import Web3.Internal as Internal exposing (CallType(..))


-- UTIL


{-| Generate a random hex number of a given length

    randomHex 32 == (Hex "0x80c729025c32243f6b71b449f423e579b35b9d79edb6f871d3399ce3d7c536")

-}
randomHex : Int -> Task Error Hex
randomHex size =
    Internal.toTask
        { method = "utils.randomHex"
        , params = Encode.list [ Encode.int size ]
        , expect = expectJson hexDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Hash a given string with Keccak256 variation of Sha3

    sha3 "Use Keccak for indigestion" == (Sha3 "0xc5a43ed1619a2850c9523be603f62c8b068c881258e4b484167c35cbf955b5fe")

-}
sha3 : String -> Task Error Sha3
sha3 val =
    Internal.toTask
        { method = "utils.sha3"
        , params = Encode.list [ Encode.string val ]
        , expect = expectJson sha3Decoder
        , callType = Sync
        , applyScope = Nothing
        }



{- Need to implement this Possibly in Web3.Eth.Solidity Module

   soliditySha3 : List SoldiityTypes -> Task Error Sha3
   soliditySha3 solidityTypes =
       Internal.toTask
           { method = "utils.soliditySha3"
           , params = encodeSolidityTypes solidityTypes
           , expect = expectJson keccakDecoder
           , callType = Sync
           }

-}


{-| Check if a given string is valid HEX

    isHex "0x" == True
    isHex "1234" == False
    isHex "0x1234" == True
    isHex "0x1h" == False

-}
isHex : String -> Task Error Bool
isHex val =
    Internal.toTask
        { method = "utils.isHex"
        , params = Encode.list [ Encode.string val ]
        , expect = expectBool
        , callType = Sync
        , applyScope = Nothing
        }


isChecksumAddress : Address -> Bool
isChecksumAddress (Address input) =
    let
        noZeroX =
            if String.slice 0 2 input == "0x" then
                String.slice 2 (String.length input) input
            else
                input

        is40Chars =
            40 == String.length noZeroX

        addrBytes =
            List.map Char.toCode <| String.toList noZeroX

        addrHash =
            ethereum_keccak_256 addrBytes

        checksumTestChar addrInt hashInt =
            let
                addrChar =
                    Char.fromCode addrInt
            in
                if hashInt > 7 && Char.toUpper addrChar /= addrChar || hashInt <= 7 && Char.toLower addrChar /= addrChar then
                    False
                else
                    True

        checksumCorrect =
            List.map2 checksumTestChar addrBytes addrHash
    in
        if is40Chars then
            all checksumCorrect
        else
            False


toAddress : String -> Maybe Address
toAddress addrStr =
    let
        isCSAddr =
            isChecksumAddress (Address addrStr)
    in
        if isCSAddr then
            Just (Address addrStr)
        else
            Nothing


{-| Check if a given address is valid.

isAddress (Address "0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232d") == True

**Note:** This function should not really be needed, but is included to wrap web3.js.
Everything wrapped in the opaque `Address` type should be a valid address.

-}
isAddress : Address -> Task Error Bool
isAddress (Address address) =
    Internal.toTask
        { method = "utils.isAddress"
        , params = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        , applyScope = Nothing
        }


{-| Convert an address to a checksumed address

    toChecksumAddress (Address "0xc1912fee45d61c87cc5ea59dae31190fffff2323")
    == (Address "0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232d")

-}
toChecksumAddress : Address -> Task Error Address
toChecksumAddress (Address address) =
    Internal.toTask
        { method = "utils.toChecksumAddress"
        , params = Encode.list [ Encode.string address ]
        , expect = expectJson addressDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Check if an address is in checksummed form

    checkAddressChecksum (Address "0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232d") == True

-}
checkAddressChecksum : Address -> Task Error Bool
checkAddressChecksum (Address address) =
    Internal.toTask
        { method = "utils.isAddress"
        , params = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        , applyScope = Nothing
        }


{-| Will convert any given value to HEX.
Number strings will interpreted as numbers. Text strings will be interpreted as UTF-8 strings.

    toHex "234" == (Hex "0xea")
    toHex "I have 100€" == (Hex "0x49206861766520313030e282ac")

-}
toHex : String -> Task Error Hex
toHex val =
    Internal.toTask
        { method = "utils.toHex"
        , params = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts HEX into a number string.

    hexToNumberString (Hex "0xea") == "234"

-}
hexToNumberString : Hex -> Task Error String
hexToNumberString (Hex val) =
    Internal.toTask
        { method = "utils.hexToNumberString"
        , params = Encode.list [ Encode.string val ]
        , expect = expectString
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts HEX into a integer.

    hexToNumber (Hex "0xea") == 234

-}
hexToNumber : Hex -> Task Error Int
hexToNumber (Hex val) =
    Internal.toTask
        { method = "utils.hexToNumber"
        , params = Encode.list [ Encode.string val ]
        , expect = expectInt
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts HEX number into BigInt

    hexToBigInt (Hex "0xea") == Pos (Magnitude [234])

-}
hexToBigInt : Hex -> Task Error BigInt
hexToBigInt hexNum =
    hexToNumberString hexNum
        |> Task.andThen
            (\numString ->
                case BigInt.fromString numString of
                    Nothing ->
                        Task.fail (Error <| "Error converting " ++ numString ++ " to BigInt")

                    Just bigInt ->
                        Task.succeed bigInt
            )


{-| Converts integer into HEX

    numberToHex 234 == (Hex "0xea")

-}
numberToHex : Int -> Task Error Hex
numberToHex number =
    Internal.toTask
        { method = "utils.numberToHex"
        , params = Encode.list [ Encode.string <| toString number ]
        , expect = expectJson hexDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts BigInt into HEX

    bigIntToHex (BigInt.fromInt 234) == (Hex "0xea")

-}
bigIntToHex : BigInt -> Task Error Hex
bigIntToHex number =
    Internal.toTask
        { method = "utils.numberToHex"
        , params = Encode.list [ Encode.string <| BigInt.toString number ]
        , expect = expectJson hexDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts HEX into Utf8

    hexToUtf8 (Hex "0x49206861766520313030e282ac") == "I have 100€"

-}
hexToUtf8 : Hex -> Task Error String
hexToUtf8 (Hex val) =
    Internal.toTask
        { method = "utils.hexToUtf8"
        , params = Encode.list [ Encode.string val ]
        , expect = expectString
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts Utf8 into HEX

    utf8ToHex "I have 100€" == (Hex "0x49206861766520313030e282ac")

-}
utf8ToHex : String -> Task Error Hex
utf8ToHex val =
    Internal.toTask
        { method = "utils.utf8ToHex"
        , params = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts HEX to Ascii

    hexToAscii (Hex "0x4920686176652031303021") == "I have 100!"

-}
hexToAscii : Hex -> Task Error String
hexToAscii (Hex val) =
    Internal.toTask
        { method = "utils.hexToAscii"
        , params =
            Encode.list [ Encode.string val ]

        -- TODO See if toAsciiDecoder is still needed
        , expect = expectJson toAsciiDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts Ascii to HEX

    asciiToHex "I have 100!" == (Hex "0x4920686176652031303021")

-}
asciiToHex : String -> Task Error Hex
asciiToHex val =
    Internal.toTask
        { method = "utils.asciiToHex"
        , params = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts HEX to Bytes

    hexToBytes (Hex "0x0102030405060708090a0f2aff") == (Bytes [1,2,3,4,5,6,7,8,9,10,15,42,255])

-}
hexToBytes : Hex -> Task Error Bytes
hexToBytes (Hex hex) =
    Internal.toTask
        { method = "utils.hexToBytes"
        , params = Encode.list [ Encode.string hex ]
        , expect = expectJson bytesDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Converts bytes to HEX

    bytesToHex (Bytes [1,2,3,4,5,6,7,8,9,10,15,42,255]) == (Hex "0x0102030405060708090a0f2aff")

-}
bytesToHex : Bytes -> Task Error Hex
bytesToHex byteArray =
    Internal.toTask
        { method = "utils.bytesToHex"
        , params = Encode.list [ encodeBytes byteArray ]
        , expect = expectJson hexDecoder
        , callType = Sync
        , applyScope = Nothing
        }


{-| Convert a given stringy EthUnit to it's Wei equivalent

    toWei Gwei "50" == Ok (BigInt.fromInt 50000000000)
    toWei Wei "40.9123" == Ok (BigInt.fromInt 40)
    toWei Kwei "40.9123" == Ok (BigInt.fromInt 40912)
    toWei Gwei "ten" == Err

-}
toWei : EthUnit -> String -> Result Error BigInt
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
                    Err (Error "There was an error calculating toWei result. However, the fault is not yours; please report this bug on github.")
    else
        Err (Error "Malformed number string passed to `toWei` method.")


{-| Convert a given BigInt EthUnit to it's Wei equivalent
-}
bigIntToWei : EthUnit -> BigInt -> BigInt
bigIntToWei unit amount =
    List.repeat (decimalShift unit) (BigInt.fromInt 10)
        |> List.foldl BigInt.mul (BigInt.fromInt 1)
        |> BigInt.mul amount


{-| Convert stringy Wei to a given EthUnit

    fromWei Gwei (BigInt.fromInt 123456789) == "0.123456789"
    fromWei Ether (BigInt.fromInt 123456789) == "0.000000000123456789"

**Note** Do not pass anything larger than MAX_SAFE_INTEGER into BigInt.fromInt
MAX_SAFE_INTEGER == 9007199254740991

-}
fromWei : EthUnit -> BigInt -> String
fromWei unit amount =
    let
        decimalIndex =
            decimalShift unit

        -- There are under 10^27 wei in existance (so we safe for the next couple of millennia).
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



--unitMap TODO Is this needed?


{-| Pad 0's to the left of a given HEX

    leftPadHex (Hex "0x80c7") == (Hex "0x000000000000000000000000000080c7")

Given HEX should be under 32 chars in length (excluding "0x") and will pad to 32 chars.

-}
leftPadHex : Hex -> Hex
leftPadHex =
    leftPadHexCustom '0' 32


{-| Pad 0's to the right of a given HEX

    rightPadHex (Hex "0x80c7") == (Hex "0x80c70000000000000000000000000000")

Given HEX should be under 32 chars in length (excluding "0x") and will pad to 32 chars.

-}
rightPadHex : Hex -> Hex
rightPadHex =
    rightPadHexCustom '0' 32



-- TODO output won't always be hex if no hexy char is provided :\


{-| Pad a given char to the left of a HEX to a certain amount

    leftPadHexCustom 'x' 16 (Hex "0x80c7") == (Hex "0xxxxxxxxxxxxx80c7")

-}
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



-- TODO output won't always be hex if no hexy char is provided :\


{-| Pad a given char to the right of a HEX to a certain amount

    rightPadHexCustom 'x' 16 (Hex "0x80c7") == (Hex "0x80c7xxxxxxxxxxxx")

-}
rightPadHexCustom : Char -> Int -> Hex -> Hex
rightPadHexCustom char amount (Hex hex) =
    String.padRight (amount + 2) char hex
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
