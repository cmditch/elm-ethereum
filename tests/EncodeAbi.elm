module EncodeAbi exposing (encodeInt)

import Abi.Encode as Abi
import BigInt exposing (BigInt)
import Eth.Utils as EthUtil
import Expect
import Test exposing (..)



-- Abi Encoders


encodeInt : Test
encodeInt =
    describe "Int Encoding"
        [ test "-120" <|
            \_ ->
                Abi.abiEncode (Abi.int <| BigInt.fromInt -120)
                    |> EthUtil.hexToString
                    |> Expect.equal "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff88"
        , test "120" <|
            \_ ->
                Abi.abiEncode (Abi.int <| BigInt.fromInt 120)
                    |> EthUtil.hexToString
                    |> Expect.equal "0x0000000000000000000000000000000000000000000000000000000000000078"
        , test "max positive int256" <|
            \_ ->
                BigInt.fromString "57896044618658097711785492504343953926634992332820282019728792003956564819967"
                    |> Maybe.map (Abi.int >> Abi.abiEncode >> EthUtil.hexToString)
                    |> Expect.equal (Just "0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")
        , test "max negative int256" <|
            \_ ->
                BigInt.fromString "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
                    |> Maybe.map (Abi.int >> Abi.abiEncode >> EthUtil.hexToString)
                    |> Expect.equal (Just "0x8000000000000000000000000000000000000000000000000000000000000000")
        ]



-- encodeComplex : Hex
-- encodeComplex =
--     let
--         testAddr =
--             Internal.Address "89d24a6b4ccb1b6faa2625fe562bdd9a23260359"
--         testAddr2 =
--             Internal.Address "c1cc40ccc2441d1e6170cc40a60aa35127cc6e7"
--         testAmount =
--             BigInt.fromString "0xde0b6b3a7640000"
--                 |> Maybe.withDefault (BigInt.fromInt 0)
--         zer =
--             (BigInt.fromInt 0)
--         functionSig =
--             EthUtils.functionSig "transfer(address,uint256)"
--                 |> EthUtils.hexToString
--         testBytes =
--             functionCall "transfer(address,uint256)" [ address testAddr2, uint testAmount ]
--     in
--         functionCall "propose(address,bytes,uint256)"
--             [ address testAddr, dynamicBytes testBytes, uint zer, dynamicBytes testBytes, dynamicBytes testBytes ]
