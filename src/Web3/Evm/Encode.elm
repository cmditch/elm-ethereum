module Web3.Evm.Encode
    exposing
        ( Encoding(..)
        , encodeData
        , encode
        , unsafeEncode
        )

import BigInt exposing (BigInt)
import Web3.Types exposing (Hex, IPFSHash)
import Web3.Utils exposing (add0x, remove0x, functionSig, ipfsToBytes32)
import Web3.Eth.Types exposing (Address)
import Web3.Evm.Utils exposing (leftPad)
import Web3.Internal.Types as Internal


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


encodeData : String -> List Encoding -> Hex
encodeData sig encodings =
    let
        sigHash =
            functionSig sig

        byteCodeEncodings =
            List.map encode encodings
                |> String.join ""
    in
        Internal.Hex <| sigHash ++ byteCodeEncodings


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


unsafeEncode : String -> Hex
unsafeEncode =
    add0x >> Internal.Hex
