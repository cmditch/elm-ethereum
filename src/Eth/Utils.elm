module Eth.Utils exposing
    ( toAddress, addressToString, addressToChecksumString, isAddress, isChecksumAddress
    , toHex, hexToString, isHex, hexToAscii, hexToUtf8, hexAppend, hexConcat
    , toTxHash, txHashToString, isTxHash
    , toBlockHash, blockHashToString, isBlockHash
    , functionSig, keccak256, isSha256, lowLevelKeccak256
    , unsafeToHex, unsafeToAddress, unsafeToTxHash, unsafeToBlockHash
    , Retry, retry, valueToMsg
    , add0x, remove0x, toByteLength, take64, drop64, leftPadTo64
    )

{-| String/Type Conversion and Application Helpers


# Address

@docs toAddress, addressToString, addressToChecksumString, isAddress, isChecksumAddress


# Hex

@docs toHex, hexToString, isHex, hexToAscii, hexToUtf8, hexAppend, hexConcat


# Transaction Hash

@docs toTxHash, txHashToString, isTxHash


# Block Hash

@docs toBlockHash, blockHashToString, isBlockHash


# SHA3

@docs functionSig, keccak256, isSha256, lowLevelKeccak256


# Unsafe

User beware!! These are sidestepping the power of Elm, and it's static types.

Undoubtedly convenient for baking values, like contract addresses, into your source code.

All values coming from the outside world, like user input or server responses, should use the safe functions.

@docs unsafeToHex, unsafeToAddress, unsafeToTxHash, unsafeToBlockHash


# Application Helpers

@docs Retry, retry, valueToMsg


# Misc

@docs add0x, remove0x, toByteLength, take64, drop64, leftPadTo64

-}

import Bool.Extra exposing (all)
import Char
import Eth.Types exposing (..)
import Hex
import Internal.Types as Internal
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Keccak.Int exposing (ethereum_keccak_256)
import Process
import Regex exposing (Regex)
import Result.Extra as Result
import String.Extra as String
import String.UTF8 as UTF8
import Task exposing (Task)



-- Address


{-| Safely convert a string into an address.

All lowercase or uppercase strings, shaped like addresses, will result in `Ok`.
Mixed case strings will return `Err` if the EIP-55 checksum is invalid.

-}
toAddress : String -> Result String Address
toAddress str =
    let
        noZeroX =
            remove0x str

        bytes32Address =
            String.right 40 str

        emptyZerosInBytes32 =
            String.left 24 noZeroX

        normalize =
            String.toLower >> Internal.Address >> Ok
    in
    -- Address is always stored without "0x"
    if String.length noZeroX == 64 && String.all ((==) '0') emptyZerosInBytes32 then
        if isUpperCaseAddress bytes32Address || isLowerCaseAddress bytes32Address then
            normalize bytes32Address

        else if isChecksumAddress bytes32Address then
            normalize bytes32Address

        else
            Err <| "Given address " ++ quote str ++ " failed the EIP-55 checksum test."

    else if String.length noZeroX /= 40 then
        Err <| "Given address " ++ quote str ++ " is not the correct length."

    else if not (isAddress noZeroX) then
        Err <| "Given address " ++ quote str ++ " contains invalid hex characters."

    else if isUpperCaseAddress noZeroX || isLowerCaseAddress noZeroX then
        normalize noZeroX

    else if isChecksumAddress noZeroX then
        normalize noZeroX

    else
        Err <| "Given address " ++ quote str ++ " failed the EIP-55 checksum test."


{-| Convert an Address to a String
-}
addressToString : Address -> String
addressToString (Internal.Address address) =
    add0x address


{-| Convert an Address to a string conforming to the EIP-55 checksum.

**Note**: This lowercases all the characters inside the `Address` and runs it through the checksum algorithm.

-}
addressToChecksumString : Address -> String
addressToChecksumString (Internal.Address address) =
    (add0x << checksumIt) address


{-| Check if given string is a valid address.

**Note**: Works on mixed case strings, with or without the 0x.

-}
isAddress : String -> Bool
isAddress =
    Regex.contains (Maybe.withDefault Regex.never (Regex.fromString "^((0[Xx]){1})?[0-9A-Fa-f]{40}$"))


{-| Check if given string is a valid checksum address.
-}
isChecksumAddress : String -> Bool
isChecksumAddress str =
    let
        checksumTestChar addrChar hashInt =
            if hashInt >= 8 && Char.isLower addrChar || hashInt < 8 && Char.isUpper addrChar then
                False

            else
                True

        ( addrChars, hashInts ) =
            checksumHelper (remove0x str)

        checksumCorrect =
            List.map2 checksumTestChar addrChars hashInts
    in
    if isAddress str then
        all checksumCorrect

    else
        False


isLowerCaseAddress : String -> Bool
isLowerCaseAddress =
    Regex.contains (Maybe.withDefault Regex.never (Regex.fromString "^((0[Xx]){1})?[0-9a-f]{40}$"))


isUpperCaseAddress : String -> Bool
isUpperCaseAddress =
    Regex.contains (Maybe.withDefault Regex.never (Regex.fromString "^((0[Xx]){1})?[0-9A-F]{40}$"))



-- Hex


{-| Safely convert a string into Hex.
-}
toHex : String -> Result String Hex
toHex str =
    if isHex str then
        Ok <| Internal.Hex (remove0x str)

    else
        Err <| "Something in here is not very hexy: " ++ quote str


{-| Convert a `Hex` into a string.
-}
hexToString : Hex -> String
hexToString (Internal.Hex hex) =
    add0x hex


{-| Check if given string is valid Hex
-}
isHex : String -> Bool
isHex =
    Regex.contains (Maybe.withDefault Regex.never (Regex.fromString "^((0[Xx]){1})?[0-9a-fA-F]+$"))


{-| Convert Given Hex into ASCII. Will fail if Hex is an uneven length.
-}
hexToAscii : Hex -> Result String String
hexToAscii (Internal.Hex hex) =
    case modBy 2 (String.length hex) == 0 of
        True ->
            String.break 2 hex
                |> List.map Hex.fromString
                |> Result.combine
                |> Result.map (String.fromList << List.map Char.fromCode)

        False ->
            Err (quote hex ++ " is not ascii hex. Uneven length. Byte pairs required.")


{-| Convert Given Hex into UTF8. Will fail if Hex is an uneven length.
-}
hexToUtf8 : Hex -> Result String String
hexToUtf8 (Internal.Hex hex) =
    case modBy 2 (String.length hex) == 0 of
        True ->
            String.break 2 hex
                |> List.map Hex.fromString
                |> Result.combine
                |> Result.andThen UTF8.toString

        False ->
            Err (quote hex ++ " is not utf8 hex. Uneven length. Byte pairs required.")


{-| Append two Hex's together.

    hexAppend (Hex 0x12) (Hex 0x34) == Hex 0x1234

-}
hexAppend : Hex -> Hex -> Hex
hexAppend (Internal.Hex hex1) (Internal.Hex hex2) =
    Internal.Hex <| hex1 ++ hex2


{-| Concatenate a list of Hex's

    hexConcat [ Hex 0x12, Hex 0x34, Hex 0x56 ] == Hex 0x 00123456

-}
hexConcat : List Hex -> Hex
hexConcat hexList =
    let
        reducer (Internal.Hex hex) accum =
            hex ++ accum
    in
    List.foldr reducer "" hexList
        |> Internal.Hex



-- Tx Hash


{-| Safely convert a string to a TxHash.
-}
toTxHash : String -> Result String TxHash
toTxHash str =
    if isSha256 str then
        Ok <| Internal.TxHash (remove0x str)

    else
        Err <| "Given txHash " ++ quote str ++ " is not valid."


{-| Convert a given TxHash to a string.
-}
txHashToString : TxHash -> String
txHashToString (Internal.TxHash txHash) =
    add0x txHash


{-| Check if given string is a valid TxHash.

i.e. Hex and 64 characters long.

-}
isTxHash : String -> Bool
isTxHash =
    isSha256



-- Block Hash


{-| Safely convert a given string to a BlockHash.
-}
toBlockHash : String -> Result String BlockHash
toBlockHash str =
    if isSha256 str then
        Ok <| Internal.BlockHash (remove0x str)

    else
        Err <| "Given blockHash " ++ quote str ++ " is not valid."


{-| Convert a given BlockHash to a string.
-}
blockHashToString : BlockHash -> String
blockHashToString (Internal.BlockHash blockHash) =
    add0x blockHash


{-| Check if given string is a valid BlockHash.

i.e. Hex and 64 characters long.

-}
isBlockHash : String -> Bool
isBlockHash =
    isSha256



-- SHA3 Helpers


{-| Convert a contract function name to it's 4-byte function signature.

    Utils.functionSig "transfer(address,uint256)" == Hex "a9059cbb"

-}
functionSig : String -> Hex
functionSig fSig =
    String.toList fSig
        |> List.map Char.toCode
        |> ethereum_keccak_256
        |> List.take 4
        |> List.map (Hex.toString >> toByteLength)
        |> String.join ""
        |> Internal.Hex


{-| Hash a given string into it's SHA3/Keccak256 form.
-}
keccak256 : String -> Hex
keccak256 str =
    String.toList str
        |> List.map Char.toCode
        |> ethereum_keccak_256
        |> List.map (Hex.toString >> toByteLength)
        |> String.join ""
        |> Internal.Hex


{-| Checks if a given string is valid hex and 64 chars long.
-}
isSha256 : String -> Bool
isSha256 =
    Regex.contains (Maybe.withDefault Regex.never (Regex.fromString "^((0[Xx]){1})?[0-9a-fA-F]{64}$"))


{-| Same as `ethereum_keccak_256` from [this](http://package.elm-lang.org/packages/prozacchiwawa/elm-keccak/latest) library.
-}
lowLevelKeccak256 : List Int -> List Int
lowLevelKeccak256 =
    ethereum_keccak_256



-- Unsafe


{-| -}
unsafeToHex : String -> Hex
unsafeToHex =
    remove0x >> String.toLower >> Internal.Hex


{-| -}
unsafeToAddress : String -> Address
unsafeToAddress =
    remove0x >> String.toLower >> Internal.Address


{-| -}
unsafeToTxHash : String -> TxHash
unsafeToTxHash =
    remove0x >> String.toLower >> Internal.TxHash


{-| -}
unsafeToBlockHash : String -> BlockHash
unsafeToBlockHash =
    remove0x >> String.toLower >> Internal.BlockHash



-- Checksum helpers


{-| Takes first 20 bytes of keccak'd address, and converts each hex char to an int
Packs this list into a tuple with the split up address chars so a comparison can be made between the two.

**Note**: Only functions which have already removed "0x" should be calling this.

-}
checksumHelper : String -> ( List Char, List Int )
checksumHelper zeroLessAddress =
    let
        addressChars =
            String.toList zeroLessAddress
    in
    addressChars
        |> List.map (Char.toLower >> Char.toCode)
        |> ethereum_keccak_256
        |> List.take 20
        |> List.map (Hex.toString >> toByteLength)
        |> String.join ""
        |> String.split ""
        |> List.map Hex.fromString
        |> Result.combine
        |> Result.withDefault []
        |> (\b -> ( addressChars, b ))


compareCharToHash : Char -> Int -> Char
compareCharToHash addrChar hashInt =
    if hashInt >= 8 then
        Char.toUpper addrChar

    else
        addrChar


checksumIt : String -> String
checksumIt str =
    let
        ( addrChars, hashInts ) =
            String.toLower str
                |> remove0x
                |> checksumHelper
    in
    List.map2 compareCharToHash addrChars hashInts
        |> String.fromList



-- App


{-| Config for a `retry` task
-}
type alias Retry =
    { attempts : Int
    , sleep : Float
    }


{-| Retry a given `Task` till it succeeds, or runs out of time.

The below will wait for 5 minutes until giving up, and polls every 5 seconds.

    pollForMinedTx : HttpProvider -> TxHash -> Task Http.Error TxReceipt
    pollForMinedTx ethNode txHash =
        Eth.getTxReceipt ethNode txHash
            |> retry { attempts = 60, sleep = 5 }

-}
retry : Retry -> Task x a -> Task x a
retry { attempts, sleep } myTask =
    let
        remaining =
            attempts - 1
    in
    myTask
        |> Task.onError
            (\x ->
                if remaining > 0 then
                    Process.sleep (sleep * 1000)
                        |> Task.andThen (\_ -> retry (Retry remaining sleep) myTask)

                else
                    Task.fail x
            )


{-| Useful for decoding past a result straight into a Msg.
Comes in handy with Eth.Sentry.Event values.

    transferDecoder : Value -> Msg
    transferDecoder =
        valueToMsg Transfer Error transferEventDecoder

    type Msg
        = Transfer (Event Transfer)
        | Error Decode.Error

-}
valueToMsg : (a -> msg) -> (Decode.Error -> msg) -> Decoder a -> (Value -> msg)
valueToMsg successMsg failureMsg decoder =
    let
        resultToMessage result =
            case result of
                Ok val ->
                    successMsg val

                Err error ->
                    failureMsg error
    in
    resultToMessage << Decode.decodeValue decoder



-- Misc


{-| Prepends a string wiht "0x"
Useful for displaying hex values
-}
add0x : String -> String
add0x str =
    if String.startsWith "0x" str || String.startsWith "0X" str then
        str

    else
        "0x" ++ str


{-| Removes "0x" or "0X" from string.
Useful for dealing with hex strings that might have "0x" prepended.
-}
remove0x : String -> String
remove0x str =
    if String.startsWith "0x" str || String.startsWith "0X" str then
        String.dropLeft 2 str

    else
        str


{-| Makes sure a string of bytes is an even number, thus valid hexdecimal.
-}
toByteLength : String -> String
toByteLength str =
    if modBy 2 (String.length str) == 1 then
        String.append "0" str

    else
        str


{-| Returns 64 chars (32 bytes) from the left side of a string.
-}
take64 : String -> String
take64 =
    String.left 64


{-| Drops 64 chars (32 bytes) from the left side of a string.
-}
drop64 : String -> String
drop64 =
    String.dropLeft 64


{-| Pads a string with '0' till it's length is 64 chars.
-}
leftPadTo64 : String -> String
leftPadTo64 str =
    String.padLeft 64 '0' str



-- Internal


quote : String -> String
quote str =
    "\"" ++ str ++ "\""
