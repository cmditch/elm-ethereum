module Web3.Evm.Encode
    exposing
        ( Encoding(..)
        , encodeData
        , encodeDataWithDebug
        , encode
        )

{-| Encode before sending RPC Calls
@docs Encoding, encodeData, encodeDataWithDebug, encode
-}

import BigInt exposing (BigInt)
import Web3.Types exposing (Hex, IPFSHash)
import Web3.Utils exposing (add0x, remove0x, functionSig, ipfsToBytes32)
import Web3.Eth.Types exposing (Address)
import Web3.Evm.Utils exposing (leftPad)
import Web3.Internal.Types as Internal


{-| -}
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
