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
import Eth.Utils exposing (functionSig, ipfsToBytes32)
import Eth.Types exposing (Address)
import Internal.Types as Internal
import Internal.Utils exposing (..)


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
                Debug.log ("Debug Contract Call " ++ sig) (functionSig sig ++ byteCodeEncodings)
            else
                functionSig sig ++ byteCodeEncodings
    in
        Internal.Hex data


{-| -}
lowLevelEncode : Encoding -> String
lowLevelEncode enc =
    case enc of
        AddressE (Internal.Address address) ->
            leftPad address

        UintE uint ->
            BigInt.toHexString uint
                |> leftPad

        BoolE True ->
            leftPad "1"

        BoolE False ->
            leftPad "0"

        DBytesE _ ->
            "not implemeneted yet"

        BytesE string ->
            remove0x string
                |> leftPad

        StringE string ->
            "not implemeneted yet"

        ListE _ ->
            "not implemeneted yet"

        IPFSHashE ipfsHash ->
            ipfsToBytes32 ipfsHash

        Custom string ->
            string
