module EncodeAbi exposing (..)

import BigInt exposing (BigInt)
import Expect
import Test exposing (..)
import Abi.Encode as Abi
import Eth.Utils as EthUtil


-- Abi Encoders


encodeInt : Test
encodeInt =
    describe "Int Encoding"
        [ test "-120" <|
            \_ ->
                Abi.encode (Abi.IntE <| BigInt.fromInt -120)
                    |> EthUtil.hexToString
                    |> Expect.equal "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff88"
        , test "120" <|
            \_ ->
                Abi.encode (Abi.IntE <| BigInt.fromInt 120)
                    |> EthUtil.hexToString
                    |> Expect.equal "0x0000000000000000000000000000000000000000000000000000000000000078"
        , test "max positive int256" <|
            \_ ->
                BigInt.fromString "57896044618658097711785492504343953926634992332820282019728792003956564819967"
                    |> Maybe.map (Abi.IntE >> Abi.encode >> EthUtil.hexToString)
                    |> Expect.equal (Just "0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")
        , test "max negative int256" <|
            \_ ->
                BigInt.fromString "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
                    |> Maybe.map (Abi.IntE >> Abi.encode >> EthUtil.hexToString)
                    |> Expect.equal (Just "0x8000000000000000000000000000000000000000000000000000000000000000")
        ]
