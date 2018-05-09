module Evm.Encode
    exposing
        ( Encoding(..)
        , encodeFunctionCall
        , encodeFunctionCallWithDebug
        , encode
        )

{-| Encode before sending RPC Calls

@docs Encoding, encodeFunctionCall, encodeFunctionCallWithDebug


# Low-Level

@docs encode

-}

import BigInt exposing (BigInt)
import Eth.Types exposing (Hex, IPFSHash)
import Eth.Utils as U exposing (functionSig, ipfsToBytes32)
import Eth.Types exposing (Address)
import Internal.Types as Internal
import Internal.Utils as IU exposing (..)


{-| Not yet implemented :

    -- DO NOT USE
    DBytesE, BytesE, StringE, ListE

-}
type Encoding
    = AddressE Address
    | UintE BigInt
    | BoolE Bool
    | DBytesE String
    | BytesE String
    | StringE String
    | ListE Encoding
    | IPFSHashE IPFSHash
    | Custom String


{-| -}
encodeFunctionCall : String -> List Encoding -> Hex
encodeFunctionCall =
    encodeFunctionCall_ False


{-| -}
encodeFunctionCallWithDebug : String -> List Encoding -> Hex
encodeFunctionCallWithDebug =
    encodeFunctionCall_ True


{-| -}
encode : Encoding -> Hex
encode =
    lowLevelEncode >> Internal.Hex



-- Internal


{-| -}
encodeFunctionCall_ : Bool -> String -> List Encoding -> Hex
encodeFunctionCall_ isDebug sig encodings =
    let
        byteCodeEncodings =
            List.map lowLevelEncode encodings
                |> String.join ""

        data =
            if isDebug then
                Debug.log ("Debug Contract Call " ++ sig) (U.hexToString (U.functionSig sig) ++ byteCodeEncodings)
            else
                (IU.remove0x <| U.hexToString <| U.functionSig sig) ++ byteCodeEncodings
    in
        Internal.Hex data


{-| -}
lowLevelEncode : Encoding -> String
lowLevelEncode enc =
    case enc of
        AddressE (Internal.Address address) ->
            IU.leftPadTo64 address

        UintE uint ->
            BigInt.toHexString uint
                |> IU.leftPadTo64

        BoolE True ->
            IU.leftPadTo64 "1"

        BoolE False ->
            IU.leftPadTo64 "0"

        DBytesE _ ->
            "not implemeneted yet"

        BytesE string ->
            IU.remove0x string
                |> IU.leftPadTo64

        StringE string ->
            "not implemeneted yet"

        ListE _ ->
            "not implemeneted yet"

        IPFSHashE ipfsHash ->
            U.ipfsToBytes32 ipfsHash
                |> \(Internal.Hex zerolessHex) -> zerolessHex

        Custom string ->
            string
