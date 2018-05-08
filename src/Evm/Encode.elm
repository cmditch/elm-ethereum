module Evm.Encode
    exposing
        ( Encoding(..)
        , encodeData
        , encodeDataWithDebug
        )

{-| Encode before sending RPC Calls

@docs Encoding, encodeData, encodeDataWithDebug

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
encodeData : String -> List Encoding -> Hex
encodeData =
    encodeData_ False


{-| -}
encodeDataWithDebug : String -> List Encoding -> Hex
encodeDataWithDebug =
    encodeData_ True



-- Internal


{-| -}
encodeData_ : Bool -> String -> List Encoding -> Hex
encodeData_ isDebug sig encodings =
    let
        byteCodeEncodings =
            List.map encode encodings
                |> String.join ""

        data =
            if isDebug then
                Debug.log ("Debug Contract Call " ++ sig) (functionSig sig ++ byteCodeEncodings)
            else
                functionSig sig ++ byteCodeEncodings
    in
        Internal.Hex data


{-| -}
encode : Encoding -> String
encode enc =
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
