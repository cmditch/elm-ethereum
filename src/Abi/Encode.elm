module Abi.Encode exposing
    ( Encoding, functionCall
    , uint8, uint16, uint24, uint32, uint40, uint48, uint56, uint64, uint72, uint80, uint88, uint96, uint104, uint112, uint120, uint128, uint136, uint144, uint152, uint160, uint168, uint176, uint184, uint192, uint200, uint208, uint216, uint224, uint232, uint240, uint248, uint256
    , int8, int16, int24, int32, int40, int48, int56, int64, int72, int80, int88, int96, int104, int112, int120, int128, int136, int144, int152, int160, int168, int176, int184, int192, int200, int208, int216, int224, int232, int240, int248, int256
    , bytes1, bytes2, bytes3, bytes4, bytes5, bytes6, bytes7, bytes8, bytes9, bytes10, bytes11, bytes12, bytes13, bytes14, bytes15, bytes16, bytes17, bytes18, bytes19, bytes20, bytes21, bytes22, bytes23, bytes24, bytes25, bytes26, bytes27, bytes28, bytes29, bytes30, bytes31, bytes32
    , bytes, string
    , bool, ipfsHash, custom
    , abiEncode
    )

{-| Encode before sending RPC Calls

@docs Encoding, functionCall


# Uint Encoding

@docs uint8, uint16, uint24, uint32, uint40, uint48, uint56, uint64, uint72, uint80, uint88, uint96, uint104, uint112, uint120, uint128, uint136, uint144, uint152, uint160, uint168, uint176, uint184, uint192, uint200, uint208, uint216, uint224, uint232, uint240, uint248, uint256


# Int Encoding

@docs int8, int16, int24, int32, int40, int48, int56, int64, int72, int80, int88, int96, int104, int112, int120, int128, int136, int144, int152, int160, int168, int176, int184, int192, int200, int208, int216, int224, int232, int240, int248, int256


# Static Bytes

@docs bytes1, bytes2, bytes3, bytes4, bytes5, bytes6, bytes7, bytes8, bytes9, bytes10, bytes11, bytes12, bytes13, bytes14, bytes15, bytes16, bytes17, bytes18, bytes19, bytes20, bytes21, bytes22, bytes23, bytes24, bytes25, bytes26, bytes27, bytes28, bytes29, bytes30, bytes31, bytes32


# Dynamic Types

@docs bytes, string, list


# Misc

@docs address, bool, ipfsHash, custom


# Low-Level

@docs abiEncode, abiEncodeList

-}

import Abi.Int as AbiInt
import BigInt exposing (BigInt)
import Eth.Types exposing (Address, Hex, IPFSHash)
import Eth.Utils
import Hex
import Internal.Types as Internal
import Internal.Utils as IU exposing (..)
import String.UTF8 as UTF8


{-| -}
type Encoding
    = AddressE Address
    | UintE BigInt
    | IntE BigInt
    | BoolE Bool
    | DBytesE Hex
    | BytesE Hex
    | StringE String
    | ListE (List Encoding)
    | IPFSHashE IPFSHash
    | CustomE String


{-| -}
functionCall : String -> List Encoding -> Hex
functionCall sig encodings =
    let
        byteCodeEncodings =
            List.map lowLevelEncode encodings
                |> lowLevelEncodeList

        data =
            Eth.Utils.functionSig sig
                |> Eth.Utils.hexToString
                |> IU.remove0x
                |> (\str -> str ++ byteCodeEncodings)
    in
    Internal.Hex data


functionCallWithDebug : Internal.DebugLogger String -> String -> List Encoding -> Hex
functionCallWithDebug logger sig encodings =
    let
        byteCodeEncodings =
            List.map lowLevelEncode encodings
                |> lowLevelEncodeList

        data =
            Eth.Utils.functionSig sig
                |> Eth.Utils.hexToString
                |> IU.remove0x
                |> (\str -> str ++ byteCodeEncodings)
                |> logger "Abi.Encode : "
    in
    Internal.Hex data



-- Encoders


{-| -}
uint8 : BigInt -> Result String Encoding
uint8 =
    uint 8


{-| -}
uint16 : BigInt -> Result String Encoding
uint16 =
    uint 16


{-| -}
uint24 : BigInt -> Result String Encoding
uint24 =
    uint 24


{-| -}
uint32 : BigInt -> Result String Encoding
uint32 =
    uint 32


{-| -}
uint40 : BigInt -> Result String Encoding
uint40 =
    uint 40


{-| -}
uint48 : BigInt -> Result String Encoding
uint48 =
    uint 48


{-| -}
uint56 : BigInt -> Result String Encoding
uint56 =
    uint 56


{-| -}
uint64 : BigInt -> Result String Encoding
uint64 =
    uint 64


{-| -}
uint72 : BigInt -> Result String Encoding
uint72 =
    uint 72


{-| -}
uint80 : BigInt -> Result String Encoding
uint80 =
    uint 80


{-| -}
uint88 : BigInt -> Result String Encoding
uint88 =
    uint 88


{-| -}
uint96 : BigInt -> Result String Encoding
uint96 =
    uint 96


{-| -}
uint104 : BigInt -> Result String Encoding
uint104 =
    uint 104


{-| -}
uint112 : BigInt -> Result String Encoding
uint112 =
    uint 112


{-| -}
uint120 : BigInt -> Result String Encoding
uint120 =
    uint 120


{-| -}
uint128 : BigInt -> Result String Encoding
uint128 =
    uint 128


{-| -}
uint136 : BigInt -> Result String Encoding
uint136 =
    uint 136


{-| -}
uint144 : BigInt -> Result String Encoding
uint144 =
    uint 144


{-| -}
uint152 : BigInt -> Result String Encoding
uint152 =
    uint 152


{-| -}
uint160 : BigInt -> Result String Encoding
uint160 =
    uint 160


{-| -}
uint168 : BigInt -> Result String Encoding
uint168 =
    uint 168


{-| -}
uint176 : BigInt -> Result String Encoding
uint176 =
    uint 176


{-| -}
uint184 : BigInt -> Result String Encoding
uint184 =
    uint 184


{-| -}
uint192 : BigInt -> Result String Encoding
uint192 =
    uint 192


{-| -}
uint200 : BigInt -> Result String Encoding
uint200 =
    uint 200


{-| -}
uint208 : BigInt -> Result String Encoding
uint208 =
    uint 208


{-| -}
uint216 : BigInt -> Result String Encoding
uint216 =
    uint 216


{-| -}
uint224 : BigInt -> Result String Encoding
uint224 =
    uint 224


{-| -}
uint232 : BigInt -> Result String Encoding
uint232 =
    uint 232


{-| -}
uint240 : BigInt -> Result String Encoding
uint240 =
    uint 240


{-| -}
uint248 : BigInt -> Result String Encoding
uint248 =
    uint 248


{-| -}
uint256 : BigInt -> Result String Encoding
uint256 =
    uint 256


{-| -}
int8 : BigInt -> Result String Encoding
int8 =
    int 8


{-| -}
int16 : BigInt -> Result String Encoding
int16 =
    int 16


{-| -}
int24 : BigInt -> Result String Encoding
int24 =
    int 24


{-| -}
int32 : BigInt -> Result String Encoding
int32 =
    int 32


{-| -}
int40 : BigInt -> Result String Encoding
int40 =
    int 40


{-| -}
int48 : BigInt -> Result String Encoding
int48 =
    int 48


{-| -}
int56 : BigInt -> Result String Encoding
int56 =
    int 56


{-| -}
int64 : BigInt -> Result String Encoding
int64 =
    int 64


{-| -}
int72 : BigInt -> Result String Encoding
int72 =
    int 72


{-| -}
int80 : BigInt -> Result String Encoding
int80 =
    int 80


{-| -}
int88 : BigInt -> Result String Encoding
int88 =
    int 88


{-| -}
int96 : BigInt -> Result String Encoding
int96 =
    int 96


{-| -}
int104 : BigInt -> Result String Encoding
int104 =
    int 104


{-| -}
int112 : BigInt -> Result String Encoding
int112 =
    int 112


{-| -}
int120 : BigInt -> Result String Encoding
int120 =
    int 120


{-| -}
int128 : BigInt -> Result String Encoding
int128 =
    int 128


{-| -}
int136 : BigInt -> Result String Encoding
int136 =
    int 136


{-| -}
int144 : BigInt -> Result String Encoding
int144 =
    int 144


{-| -}
int152 : BigInt -> Result String Encoding
int152 =
    int 152


{-| -}
int160 : BigInt -> Result String Encoding
int160 =
    int 160


{-| -}
int168 : BigInt -> Result String Encoding
int168 =
    int 168


{-| -}
int176 : BigInt -> Result String Encoding
int176 =
    int 176


{-| -}
int184 : BigInt -> Result String Encoding
int184 =
    int 184


{-| -}
int192 : BigInt -> Result String Encoding
int192 =
    int 192


{-| -}
int200 : BigInt -> Result String Encoding
int200 =
    int 200


{-| -}
int208 : BigInt -> Result String Encoding
int208 =
    int 208


{-| -}
int216 : BigInt -> Result String Encoding
int216 =
    int 216


{-| -}
int224 : BigInt -> Result String Encoding
int224 =
    int 224


{-| -}
int232 : BigInt -> Result String Encoding
int232 =
    int 232


{-| -}
int240 : BigInt -> Result String Encoding
int240 =
    int 240


{-| -}
int248 : BigInt -> Result String Encoding
int248 =
    int 248


{-| -}
int256 : BigInt -> Result String Encoding
int256 =
    int 256


{-| -}
bytes1 : Hex -> Result String Encoding
bytes1 =
    staticBytes 1


{-| -}
bytes2 : Hex -> Result String Encoding
bytes2 =
    staticBytes 2


{-| -}
bytes3 : Hex -> Result String Encoding
bytes3 =
    staticBytes 3


{-| -}
bytes4 : Hex -> Result String Encoding
bytes4 =
    staticBytes 4


{-| -}
bytes5 : Hex -> Result String Encoding
bytes5 =
    staticBytes 5


{-| -}
bytes6 : Hex -> Result String Encoding
bytes6 =
    staticBytes 6


{-| -}
bytes7 : Hex -> Result String Encoding
bytes7 =
    staticBytes 7


{-| -}
bytes8 : Hex -> Result String Encoding
bytes8 =
    staticBytes 8


{-| -}
bytes9 : Hex -> Result String Encoding
bytes9 =
    staticBytes 9


{-| -}
bytes10 : Hex -> Result String Encoding
bytes10 =
    staticBytes 10


{-| -}
bytes11 : Hex -> Result String Encoding
bytes11 =
    staticBytes 11


{-| -}
bytes12 : Hex -> Result String Encoding
bytes12 =
    staticBytes 12


{-| -}
bytes13 : Hex -> Result String Encoding
bytes13 =
    staticBytes 13


{-| -}
bytes14 : Hex -> Result String Encoding
bytes14 =
    staticBytes 14


{-| -}
bytes15 : Hex -> Result String Encoding
bytes15 =
    staticBytes 15


{-| -}
bytes16 : Hex -> Result String Encoding
bytes16 =
    staticBytes 16


{-| -}
bytes17 : Hex -> Result String Encoding
bytes17 =
    staticBytes 17


{-| -}
bytes18 : Hex -> Result String Encoding
bytes18 =
    staticBytes 18


{-| -}
bytes19 : Hex -> Result String Encoding
bytes19 =
    staticBytes 19


{-| -}
bytes20 : Hex -> Result String Encoding
bytes20 =
    staticBytes 20


{-| -}
bytes21 : Hex -> Result String Encoding
bytes21 =
    staticBytes 21


{-| -}
bytes22 : Hex -> Result String Encoding
bytes22 =
    staticBytes 22


{-| -}
bytes23 : Hex -> Result String Encoding
bytes23 =
    staticBytes 23


{-| -}
bytes24 : Hex -> Result String Encoding
bytes24 =
    staticBytes 24


{-| -}
bytes25 : Hex -> Result String Encoding
bytes25 =
    staticBytes 25


{-| -}
bytes26 : Hex -> Result String Encoding
bytes26 =
    staticBytes 26


{-| -}
bytes27 : Hex -> Result String Encoding
bytes27 =
    staticBytes 27


{-| -}
bytes28 : Hex -> Result String Encoding
bytes28 =
    staticBytes 28


{-| -}
bytes29 : Hex -> Result String Encoding
bytes29 =
    staticBytes 29


{-| -}
bytes30 : Hex -> Result String Encoding
bytes30 =
    staticBytes 30


{-| -}
bytes31 : Hex -> Result String Encoding
bytes31 =
    staticBytes 31


{-| -}
bytes32 : Hex -> Result String Encoding
bytes32 =
    staticBytes 32


{-| -}
bool : Bool -> Encoding
bool =
    BoolE


{-| -}
staticBytes : Int -> Hex -> Result String Encoding
staticBytes size bytes_ =
    let
        rawBytes =
            Eth.Utils.hexToString bytes_
                |> IU.remove0x

        bytesLength =
            String.length rawBytes
    in
    if size <= 0 || size > 32 then
        Err <| "Invalid size: " ++ String.fromInt size

    else if modBy 2 bytesLength == 0 && bytesLength == size * 2 then
        Ok <| BytesE bytes_

    else
        Err <|
            "Bytes overflow: 0x"
                ++ rawBytes
                ++ " is larger than bytes"
                ++ String.fromInt size


{-| -}
bytes : Hex -> Encoding
bytes =
    DBytesE


{-| -}
list : List Encoding -> Encoding
list =
    ListE



-- DBytesE >> Ok


{-| -}
string : String -> Encoding
string =
    StringE


{-| -}
ipfsHash : IPFSHash -> Encoding
ipfsHash =
    IPFSHashE


{-| -}
custom : String -> Encoding
custom =
    CustomE



-- Low Level


{-| -}
abiEncode : Encoding -> Hex
abiEncode =
    lowLevelEncode >> (\v -> lowLevelEncodeList [ v ]) >> Internal.Hex


{-| -}
abiEncodeList : List Encoding -> Hex
abiEncodeList =
    List.map lowLevelEncode >> lowLevelEncodeList >> Internal.Hex



-- Internal


{-| Low level uint helper
-}
uint : Int -> BigInt -> Result String Encoding
uint size num =
    if modBy 8 size /= 0 || size <= 0 || size > 256 then
        Err <| "Invalid size: " ++ String.fromInt size

    else if BigInt.lt num (BigInt.pow (BigInt.fromInt 2) (BigInt.fromInt size)) then
        -- TODO Figure out if it's 2^n or (2^n - 1), e.g. uint8 should not be over 255 or 256 ?
        Ok <| UintE num

    else
        Err <|
            "Uint overflow: "
                ++ BigInt.toString num
                ++ " is larger than uint"
                ++ String.fromInt size


{-| Low level int helper
-}
int : Int -> BigInt -> Result String Encoding
int size num =
    if modBy 8 size /= 0 || size <= 0 || size > 256 then
        Err <| "Invalid size: " ++ String.fromInt size

    else if ... then
        -- TODO Figure out if int8 should not be over 127 or 128 ?
        Ok <| IntE num

    else
        -- Account for overflow and underflow
        Err <|
            "Int overflow/underflow: "
                ++ BigInt.toString num
                ++ " is larger than uint"
                ++ String.fromInt size


{-| (Maybe (Size of Dynamic Value), Value)
-}
type alias LowLevelEncoding =
    ( Maybe Int, String )


{-| -}
toStaticLLEncoding : String -> LowLevelEncoding
toStaticLLEncoding strVal =
    ( Nothing
    , IU.leftPadMod64 strVal
    )


{-| -}
toDynamicLLEncoding : String -> LowLevelEncoding
toDynamicLLEncoding strVal =
    ( Just <| String.length strVal // 2
    , rightPadMod64 strVal
    )


{-| -}
lowLevelEncode : Encoding -> LowLevelEncoding
lowLevelEncode enc =
    case enc of
        AddressE (Internal.Address address_) ->
            toStaticLLEncoding address_

        UintE uint_ ->
            BigInt.toHexString uint_
                |> toStaticLLEncoding

        IntE int_ ->
            AbiInt.toString int_
                |> toStaticLLEncoding

        BoolE True ->
            toStaticLLEncoding "1"

        BoolE False ->
            toStaticLLEncoding "0"

        DBytesE (Internal.Hex hexString) ->
            toDynamicLLEncoding hexString

        BytesE (Internal.Hex hexString) ->
            IU.remove0x hexString
                |> toStaticLLEncoding

        StringE string_ ->
            stringToHex string_
                |> toDynamicLLEncoding

        ListE encodings ->
            abiEncodeList encodings
                |> (\(Internal.Hex hexString) ->
                        toDynamicLLEncoding hexString
                   )

        IPFSHashE ipfsHash_ ->
            Eth.Utils.ipfsToBytes32 ipfsHash_
                |> (\(Internal.Hex zerolessHex) ->
                        zerolessHex
                            |> toStaticLLEncoding
                   )

        CustomE string_ ->
            IU.remove0x string_
                |> toStaticLLEncoding


lowLevelEncodeList : List LowLevelEncoding -> String
lowLevelEncodeList vals =
    let
        reducer : LowLevelEncoding -> ( Int, String, String ) -> ( Int, String, String )
        reducer ( mLength, val ) ( dynValPointer, staticVals, dynamicVals ) =
            case mLength of
                Just length ->
                    let
                        newDynValPointer =
                            dynValPointer + 32 + (String.length val // 2)

                        newStaticVals =
                            Hex.toString dynValPointer
                                |> IU.leftPadTo64

                        newDynVals =
                            Hex.toString length
                                |> IU.leftPadTo64
                                |> (\lengthInHex -> lengthInHex ++ val)
                    in
                    ( newDynValPointer
                      -- newPointer - = previousPointer + (length of hexLengthWord) + (length of val words)
                    , staticVals ++ newStaticVals
                    , dynamicVals ++ newDynVals
                    )

                Nothing ->
                    ( dynValPointer
                    , staticVals ++ val
                    , dynamicVals
                    )
    in
    List.foldl reducer ( List.length vals * 32, "", "" ) vals
        |> (\( _, sVals, dVals ) -> sVals ++ dVals)



-- Helpers
-- Move to utils

{-| Right pads a string with "0"'s till (strLength % 64 == 0)
64 chars or 32 bytes is the size of an EVM word
-}
rightPadMod64 : String -> String
rightPadMod64 str =
    str ++ String.repeat (String.length str |> tillMod64) "0"


tillMod64 : Int -> Int
tillMod64 n =
    64 - modBy 64 n


{-| Converts utf8 string to string of hex
-}
stringToHex : String -> String
stringToHex strVal =
    UTF8.toBytes strVal
        |> List.map Hex.toString
        |> String.join ""
