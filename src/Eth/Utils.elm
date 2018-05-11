module Eth.Utils
    exposing
        ( -- ADDRESS
          toAddress
        , addressToString
        , addressToChecksumString
        , isAddress
        , isChecksumAddress
          -- HEX
        , toHex
        , hexToString
          -- , hexToUtf8
        , hexToAscii
        , isHex
          -- TX-HASH
        , toTxHash
        , txHashToString
          -- , isTxHash
          -- BLOCK-HASH
        , toBlockHash
        , blockHashToString
          -- , isBlockHash
          --SHA3
        , functionSig
        , keccak256
        , isSha256
          -- IPFS-HASH
        , toIPFSHash
        , ipfsHashToString
        , ipfsToBytes32
          -- , isIPFSHash
          -- UNSAFE
        , unsafeToAddress
        , unsafeToHex
        , unsafeToTxHash
        , unsafeToBlockHash
        , unsafeToIPFSHash
          -- APPLICATION UTILS
        , Retry
        , retry
        , valueToMsg
        )

{-| String/Type Conversion and Application Helpers


# Address

@docs toAddress, addressToString, addressToChecksumString, isAddress, isChecksumAddress


# Hex

@docs toHex, hexToString, isHex, hexToAscii


# Transaction Hash

@docs toTxHash, txHashToString


# Block Hash

@docs toBlockHash, blockHashToString


# SHA3

@docs functionSig, keccak256, isSha256


# IPFS

@docs ipfsHashToString, ipfsToBytes32, toIPFSHash


# Unsafe

@docs unsafeToHex, unsafeToAddress, unsafeToTxHash, unsafeToBlockHash, unsafeToIPFSHash


# Application Helpers

@docs Retry, retry, valueToMsg

-}

import Base58
import BigInt exposing (BigInt)
import Bool.Extra exposing (all)
import Char
import Eth.Types exposing (..)
import Hex
import Internal.Types as Internal
import Internal.Utils as Internal exposing (..)
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Keccak exposing (ethereum_keccak_256)
import Process
import Regex exposing (Regex)
import Result.Extra as Result
import String.Extra as String
import Task exposing (Task)
import Time


-- Address


{-| Make an Address

All lowercase or uppercase strings, shaped like addresses, will result in `Ok`.
Mixed case strings will return `Err` if checksum is invalid.

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
    in
        -- Address is always stored in lowercase and without "0x"
        if String.length noZeroX == 64 && String.all ((==) '0') emptyZerosInBytes32 then
            if isUpperCaseAddress bytes32Address || isLowerCaseAddress bytes32Address then
                Ok <| Internal.Address <| String.toLower bytes32Address
            else if (isChecksumStringyAddress bytes32Address) then
                Ok <| Internal.Address <| String.toLower bytes32Address
            else
                Err <| "Given address " ++ quote str ++ " failed the EIP-55 checksum test."
        else if String.length noZeroX < 40 then
            Err <| "Given address " ++ quote str ++ " is too short"
        else if String.length noZeroX > 40 then
            Err <| "Given address " ++ quote str ++ " is too long"
        else if not (isAddress noZeroX) then
            Err <| "Given address " ++ quote str ++ " contains invalid hex characters."
        else if isUpperCaseAddress noZeroX || isLowerCaseAddress noZeroX then
            Ok <| Internal.Address (String.toLower noZeroX)
        else if (isChecksumStringyAddress noZeroX) then
            Ok <| Internal.Address (String.toLower noZeroX)
        else
            Err <| "Given address " ++ quote str ++ " failed the EIP-55 checksum test."


{-| -}
toChecksumAddress : String -> Result String Address
toChecksumAddress str =
    if isAddress str then
        Ok <| Internal.Address <| checksumIt <| remove0x str
    else
        Err <| "Given address " ++ quote str ++ " is not a valid Ethereum address."


{-| Returns Address String
-}
addressToString : Address -> String
addressToString (Internal.Address address) =
    add0x address


{-| Returns Checksummed Address String
-}
addressToChecksumString : Address -> String
addressToChecksumString (Internal.Address address) =
    (add0x << checksumIt) address


{-| -}
isAddress : String -> Bool
isAddress =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9A-Fa-f]{40}$")


{-| -}
isChecksumAddress : Address -> Bool
isChecksumAddress (Internal.Address address) =
    isChecksumStringyAddress address


{-| -}
isChecksumStringyAddress : String -> Bool
isChecksumStringyAddress str =
    let
        checksumTestChar addrChar hashInt =
            if hashInt >= 8 && Char.isLower addrChar || hashInt < 8 && Char.isUpper addrChar then
                False
            else
                True

        checksumCorrect =
            uncurry (List.map2 checksumTestChar) (checksumHelper str)
    in
        if isAddress str then
            all checksumCorrect
        else
            False


{-| -}
isLowerCaseAddress : String -> Bool
isLowerCaseAddress =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9a-f]{40}$")


{-| -}
isUpperCaseAddress : String -> Bool
isUpperCaseAddress =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9A-F]{40}$")



-- Hex


{-| -}
toHex : String -> Result String Hex
toHex str =
    if isHex str then
        Ok <| Internal.Hex (remove0x str)
    else
        Err <| "Something in here is not very hexy: " ++ quote str


{-| -}
hexToString : Hex -> String
hexToString (Internal.Hex hex) =
    add0x hex


{-| -}
isHex : String -> Bool
isHex =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9a-fA-F]+$")


{-| -}
hexToAscii : Hex -> Result String String
hexToAscii (Internal.Hex hex) =
    case String.length hex % 2 == 0 of
        True ->
            String.break 2 hex
                |> List.map Hex.fromString
                |> Result.combine
                |> Result.map (String.fromList << List.map Char.fromCode)

        False ->
            Err (quote hex ++ " is not ascii hex. Uneven length. Byte pairs required.")


{-| -}
hexAppend : Hex -> Hex -> Hex
hexAppend (Internal.Hex hex1) (Internal.Hex hex2) =
    Internal.Hex <| hex1 ++ hex2


{-| -}
hexConcat : List Hex -> Hex
hexConcat hexList =
    let
        reducer (Internal.Hex hex) accum =
            hex ++ accum
    in
        List.foldr reducer "" hexList
            |> Internal.Hex



-- Tx Hash


{-| -}
toTxHash : String -> Result String TxHash
toTxHash str =
    if isSha256 str then
        Ok <| Internal.TxHash (remove0x str)
    else
        Err <| "Given txHash " ++ quote str ++ " is not valid."


{-| -}
txHashToString : TxHash -> String
txHashToString (Internal.TxHash txHash) =
    add0x txHash



-- Block Hash


{-| -}
toBlockHash : String -> Result String BlockHash
toBlockHash str =
    if isSha256 str then
        Ok <| Internal.BlockHash (remove0x str)
    else
        Err <| "Given blockHash " ++ quote str ++ " is not valid."


{-| -}
blockHashToString : BlockHash -> String
blockHashToString (Internal.BlockHash blockHash) =
    add0x blockHash



-- SHA3 Helpers


{-| -}
functionSig : String -> Hex
functionSig fSig =
    String.toList fSig
        |> List.map Char.toCode
        |> ethereum_keccak_256
        |> List.take 4
        |> List.map (Hex.toString >> toByteLength)
        |> String.join ""
        |> Internal.Hex


{-| -}
keccak256 : String -> Hex
keccak256 str =
    String.toList str
        |> List.map Char.toCode
        |> ethereum_keccak_256
        |> List.map (Hex.toString >> toByteLength)
        |> String.join ""
        |> Internal.Hex


{-| -}
isSha256 : String -> Bool
isSha256 =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9a-fA-F]{64}$")


{-| -}
lowLevelKeccak256 : List Int -> List Int
lowLevelKeccak256 =
    ethereum_keccak_256



-- IPFS


{-| -}
ipfsHashToString : IPFSHash -> String
ipfsHashToString (Internal.IPFSHash str) =
    str


{-| Prepares IPFS Hash to store as soldity bytes32
-}
ipfsToBytes32 : IPFSHash -> Hex
ipfsToBytes32 (Internal.IPFSHash str) =
    Base58.decode str
        |> Result.map (BigInt.toHexString >> String.dropLeft 4 >> Internal.Hex)
        |> Result.withDefault (Internal.Hex "Impossible error on ipfsToBytes32. Please report this bug on github.")


{-| -}
toIPFSHash : String -> Result String IPFSHash
toIPFSHash str =
    if String.length str /= 46 then
        Err <| str ++ " is an invalid IPFS Hash. Must be 46 chars long."
    else if String.left 2 str /= "Qm" then
        Err <| str ++ " is an invalid IPFS Hash. Must begin with \"Qm\"."
    else
        Base58.decode str
            |> Result.andThen (\_ -> Ok <| Internal.IPFSHash str)



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


{-| -}
unsafeToIPFSHash : String -> IPFSHash
unsafeToIPFSHash =
    remove0x >> Internal.IPFSHash



-- Checksum helpers


{-| Takes first 20 bytes of keccak'd address, and converts each hex char to an int
Packs this list into a tuple with the split up address chars so a comparison can be made between the two.

Note: Only functions which have already removed "0x" should be calling this.

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
            |> (,) addressChars


compareCharToHash : Char -> Int -> Char
compareCharToHash addrChar hashInt =
    if hashInt >= 8 then
        Char.toUpper addrChar
    else
        addrChar


checksumIt : String -> String
checksumIt str =
    uncurry (List.map2 compareCharToHash) (checksumHelper str)
        |> String.fromList



-- App


{-| -}
type alias Retry =
    { attempts : Int
    , sleep : Float
    }


{-| -}
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
                        Process.sleep (sleep * Time.second)
                            |> Task.andThen (\_ -> retry (Retry remaining sleep) myTask)
                    else
                        Task.fail x
                )


{-| Help with decoding past a result straight into a Msg
-}
valueToMsg : (a -> msg) -> (String -> msg) -> Decoder a -> (Value -> msg)
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
