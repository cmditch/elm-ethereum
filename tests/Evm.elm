module Evm exposing (..)

-- import Fuzz exposing (Fuzzer, int, list, string)

import BigInt
import Expect
import Test exposing (..)
import Evm.Decode as EvmDecode


intTests : Test
intTests =
    describe "Ints"
        [ test "int with 1 at start" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x1000"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "4096")
        , test "zero int" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x0000000000000000000000000000000000000000000000000000000000000000"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "0")
        , test "int with 1 at end" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x0000000000000000000000000000000000000000000000000000000000000001"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "1")
        , test "int with all f's" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-1")
        , test "int 2" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x0000000000000000000000000000000000000000000000000000000000000002"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "2")
        , test "int -2" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-2")
        , test "int with letter at start" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x000000000000000000000000000000000000000000000000000000000000000a"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "10")
        , test "int -10" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-10")
        , test "int 11" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x000000000000000000000000000000000000000000000000000000000000000b"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "11")
        , test "int -11" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-11")
        , test "max positive int8" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x000000000000000000000000000000000000000000000000000000000000007f"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "127")
        , test "int -127" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff81"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-127")
        , test "max negative int8" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff80"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-128")
        , test "max positive int16" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x0000000000000000000000000000000000000000000000000000000000007fff"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "32767")
        , test "int -32767" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8001"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-32767")
        , test "max negative int16" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8000"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-32768")
        , test "max positive int256" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "57896044618658097711785492504343953926634992332820282019728792003956564819967")
        , test "max negative int256" <|
            \_ ->
                EvmDecode.fromString EvmDecode.int "0x8000000000000000000000000000000000000000000000000000000000000000"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-57896044618658097711785492504343953926634992332820282019728792003956564819968")
        ]
