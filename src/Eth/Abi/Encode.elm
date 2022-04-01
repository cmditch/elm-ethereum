module Eth.Abi.Encode exposing
    ( Encoding(..), functionCall
    , uint, int, staticBytes
    , string, list, bytes
    , address, bool
    , abiEncode, abiEncodeList, stringToHex
    , staticList, tuple
    )

{-| Encode before sending RPC Calls

@docs Encoding, functionCall


# Static Type Encoding

@docs uint, int, staticBytes


# Dynamic Types

@docs string, list, bytes


# Misc

@docs address, bool, custom


# Low-Level

@docs abiEncode, abiEncodeList, stringToHex

-}

import BigInt exposing (BigInt)
import Dict exposing (Dict)
import Eth.Abi.Int as AbiInt
import Eth.Types exposing (Address, Hex)
import Eth.Utils exposing (leftPadTo64, remove0x, unsafeToHex)
import Hex
import Internal.Types as Internal
import String.UTF8 as UTF8


{-| -}
functionCall : String -> List Encoding -> Result String Hex
functionCall abiSig args =
    abiEncodeList_ args
        |> Result.map (\calldata -> Internal.Hex (remove0x abiSig ++ calldata))



-- Encoders


{-| -}
uint : BigInt -> Encoding
uint =
    BigInt.toHexString >> leftPadTo64 >> EValue


{-| -}
int : BigInt -> Encoding
int =
    AbiInt.toString >> leftPadTo64 >> EValue


{-| -}
address : Address -> Encoding
address (Internal.Address addr) =
    addr |> leftPadTo64 |> EValue


{-| -}
bool : Bool -> Encoding
bool v =
    (if v then
        "1"

     else
        "0"
    )
        |> leftPadTo64
        |> EValue


{-| Encodes inline bytes (fixed size byte array)
-}
staticBytes : Hex -> Encoding
staticBytes (Internal.Hex hex) =
    hex |> remove0x |> EValue


{-| Creates a pointer to a byte array
-}
bytes : Hex -> Encoding
bytes =
    EDynamicBytes >> EPointerTo


{-| Inline list (fixed size)
-}
staticList : List Encoding -> Encoding
staticList =
    EInline


tuple : List Encoding -> Encoding
tuple props =
    -- Tuples are stored as a pointer when any of their members are pointers
    -- but as inlines when all members are fixed-sized
    -- Why ? 🤷‍♂️ No idea... (their dynamic members could be stored as a fixed-size pointer, removing the need for a pointer to the structure body itself)
    -- see js implem here https://github.com/ethers-io/ethers.js/blob/master/packages/abi/src.ts/coders/tuple.ts
    if List.any isDynamic props then
        EPointerTo (EInline props)

    else
        EInline props


{-| Dynamic list
-}
list : List Encoding -> Encoding
list =
    EDynamicList



-- DBytesE >> Ok


{-| -}
string : String -> Encoding
string =
    stringToHex >> unsafeToHex >> EDynamicBytes >> EPointerTo


{-| -}
abiEncode : Encoding -> Result String Hex
abiEncode e =
    [ e ] |> abiEncodeList


{-| -}
abiEncodeList : List Encoding -> Result String Hex
abiEncodeList =
    abiEncodeList_ >> Result.map Internal.Hex


abiEncodeList_ : List Encoding -> Result String String
abiEncodeList_ data =
    computeLayout 2 [ { id = 1, offset = 0, data = data } ]
        |> layoutToHex


type Encoding
    = -- A 32 bytes value (or shorter, which will be padded with zeros)
      EValue String
      -- Will write dynamic bytes (32 bytes for length, then data) in place
    | EDynamicBytes Hex
      -- Will write a dynamic list (32 bytes for length, then data) in place
    | EDynamicList (List Encoding)
      -- Write multiple elements, one after another, in place
    | EInline (List Encoding)
      -- Write a pointer to a value, and defers the writing of those values actual bodies
    | EPointerTo Encoding


type DataItem
    = -- a value, with an id
      DValue String -- value
    | DPointerTo Int Int -- pointer to a given block ID, its origin block ID



-- Block id, block header size (pointer address offset), and data


type alias DataBlock =
    { id : Int, offset : Int, data : List DataItem }


type alias BlockToLayout =
    { id : Int
    , offset : Int
    , data : List Encoding
    }


computeLayout : Int -> List BlockToLayout -> List DataBlock
computeLayout cnt toLayout =
    case toLayout of
        [] ->
            []

        b :: bs ->
            let
                -- compute this block's layout, and get back some queued blocks
                ( newCnt, blockLayout, queuedBlocks ) =
                    computeOneLayout b.id b.data cnt

                block =
                    { id = b.id, offset = b.offset, data = blockLayout }
            in
            block :: computeLayout newCnt (queuedBlocks ++ bs)


computeOneLayout : Int -> List Encoding -> Int -> ( Int, List DataItem, List BlockToLayout )
computeOneLayout blockId toLayout cnt =
    case toLayout of
        [] ->
            ( cnt, [], [] )

        i :: is ->
            case i of
                EValue x ->
                    ---------- simple values are stored as it, grouped 64-by-64 (i.e. 256 bits-by-256 bits)
                    let
                        -- build next values
                        ( newCnt, nexts, queue ) =
                            computeOneLayout blockId is cnt

                        -- all values must be a multiple of 64
                        paddedValue =
                            rightPadMod64 x

                        -- build this value
                        this =
                            DValue paddedValue
                    in
                    ( newCnt, this :: nexts, queue )

                EPointerTo toData ->
                    ---------- pointers are stored as a pointer to the inner value
                    let
                        pointedId =
                            cnt

                        -- build next values
                        ( newCnt, nexts, queue ) =
                            computeOneLayout blockId is (cnt + 1)

                        -- build this value
                        this =
                            DPointerTo pointedId blockId

                        dataBlock : BlockToLayout
                        dataBlock =
                            { id = pointedId, offset = 0, data = [ toData ] }
                    in
                    -- build the pointer
                    ( newCnt, this :: nexts, dataBlock :: queue )

                EDynamicBytes (Internal.Hex hex) ->
                    let
                        -- bits (*4) ? or bytes (//2) ?
                        bytesLen =
                            (String.length hex // 2)
                                |> BigInt.fromInt
                    in
                    computeOneLayout blockId (uint bytesLen :: EValue hex :: is) cnt

                EDynamicList listVals ->
                    ---------- dynamic lists are stored as a pointer to the array length (which wil lbe followed by list elements) somewhere in encoded value
                    let
                        -- encode array elements on a new stack
                        listLen =
                            List.length listVals |> BigInt.fromInt |> uint

                        -- build next values
                        ( newCnt, nexts, queue ) =
                            computeOneLayout blockId is (cnt + 1)

                        -- build this value
                        this =
                            DPointerTo cnt blockId

                        listBody : BlockToLayout
                        listBody =
                            { id = cnt, offset = 32, data = listLen :: listVals }
                    in
                    -- build the pointer
                    ( newCnt, this :: nexts, listBody :: queue )

                EInline vals ->
                    ---------- Consecutive inline elements
                    computeOneLayout blockId (vals ++ is) cnt


measureLayout : List DataBlock -> ( List DataItem, Dict Int ( Int, Int ) )
measureLayout blocks =
    let
        ( _, lst, retPos ) =
            blocks
                |> List.foldl
                    (\{ id, offset, data } ( thisPos, prev, posById ) ->
                        let
                            newPos =
                                thisPos + measureBlock data
                        in
                        ( newPos, prev ++ data, Dict.insert id ( thisPos, thisPos + offset ) posById )
                    )
                    ( 0, [], Dict.empty )
    in
    ( lst, retPos )


measureBlock : List DataItem -> Int
measureBlock =
    List.foldl
        (\val acc ->
            case val of
                DValue str ->
                    acc + String.length str // 2

                DPointerTo _ _ ->
                    acc + 32
        )
        0


layoutToHex : List DataBlock -> Result String String
layoutToHex stack =
    let
        ( lst, pos ) =
            measureLayout stack
    in
    lst
        |> List.foldl
            (\v acc ->
                case acc of
                    Err e ->
                        Err e

                    Ok prev ->
                        case v of
                            DValue str ->
                                Ok (str :: prev)

                            DPointerTo to from ->
                                case ( Dict.get to pos, Dict.get from pos ) of
                                    ( Just ( toPos, _ ), Just ( _, fromPos ) ) ->
                                        let
                                            encodedPtr =
                                                (toPos - fromPos) |> BigInt.fromInt |> BigInt.toHexString |> leftPadTo64
                                        in
                                        Ok (encodedPtr :: prev)

                                    _ ->
                                        Err <| "LayoutToHex: Pointer not found"
            )
            (Ok [])
        |> Result.map List.reverse
        |> Result.map (String.join "")


{-| Function that takes a list of values to encode, the current ID of the first value to encode,
and which returns the next avaialble ID and the flatten layout of encoded values (with their ids)
-}
isDynamic : Encoding -> Bool
isDynamic e =
    case e of
        EDynamicBytes _ ->
            True

        EDynamicList _ ->
            True

        EPointerTo _ ->
            True

        _ ->
            False


{-| Right pads a string with "0"'s till (strLength % 64 == 0)
64 chars or 32 bytes is the size of an EVM word
-}
rightPadMod64 : String -> String
rightPadMod64 str =
    str ++ String.repeat (String.length str |> tillMod64) "0"


tillMod64 : Int -> Int
tillMod64 n =
    case modBy 64 n of
        0 ->
            0

        n_ ->
            64 - n_


{-| Converts utf8 string to string of hex
-}
stringToHex : String -> String
stringToHex strVal =
    UTF8.toBytes strVal
        |> List.map (Hex.toString >> String.padLeft 2 '0')
        |> String.join ""
