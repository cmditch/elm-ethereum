module Evm exposing (..)

-- import Fuzz exposing (Fuzzer, int, list, string)

import BigInt exposing (BigInt)
import Expect
import Test exposing (..)
import Evm.Decode as Evm


-- Evm Decoders


intTests : Test
intTests =
    describe "Ints"
        [ test "int with 1 at start" <|
            \_ ->
                Evm.fromString Evm.int "0x1000"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "4096")
        , test "zero int" <|
            \_ ->
                Evm.fromString Evm.int "0x0000000000000000000000000000000000000000000000000000000000000000"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "0")
        , test "int with 1 at end" <|
            \_ ->
                Evm.fromString Evm.int "0x0000000000000000000000000000000000000000000000000000000000000001"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "1")
        , test "int with all f's" <|
            \_ ->
                Evm.fromString Evm.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-1")
        , test "int 2" <|
            \_ ->
                Evm.fromString Evm.int "0x0000000000000000000000000000000000000000000000000000000000000002"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "2")
        , test "int -2" <|
            \_ ->
                Evm.fromString Evm.int "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-2")
        , test "int with letter at start" <|
            \_ ->
                Evm.fromString Evm.int "0x000000000000000000000000000000000000000000000000000000000000000a"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "10")
        , test "int -10" <|
            \_ ->
                Evm.fromString Evm.int "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-10")
        , test "int 11" <|
            \_ ->
                Evm.fromString Evm.int "0x000000000000000000000000000000000000000000000000000000000000000b"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "11")
        , test "int -11" <|
            \_ ->
                Evm.fromString Evm.int "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-11")
        , test "max positive int8" <|
            \_ ->
                Evm.fromString Evm.int "0x000000000000000000000000000000000000000000000000000000000000007f"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "127")
        , test "int -127" <|
            \_ ->
                Evm.fromString Evm.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff81"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-127")
        , test "max negative int8" <|
            \_ ->
                Evm.fromString Evm.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff80"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-128")
        , test "max positive int16" <|
            \_ ->
                Evm.fromString Evm.int "0x0000000000000000000000000000000000000000000000000000000000007fff"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "32767")
        , test "int -32767" <|
            \_ ->
                Evm.fromString Evm.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8001"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-32767")
        , test "max negative int16" <|
            \_ ->
                Evm.fromString Evm.int "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8000"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-32768")
        , test "max positive int256" <|
            \_ ->
                Evm.fromString Evm.int "0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "57896044618658097711785492504343953926634992332820282019728792003956564819967")
        , test "max negative int256" <|
            \_ ->
                Evm.fromString Evm.int "0x8000000000000000000000000000000000000000000000000000000000000000"
                    |> Result.map BigInt.toString
                    |> Expect.equal (Ok "-57896044618658097711785492504343953926634992332820282019728792003956564819968")
        ]



-- ComplexStorage Test


complexStorage : Test
complexStorage =
    describe "Contract Call Decoding"
        [ test "decode ComplexStorage.getVals()" <|
            \_ ->
                Evm.fromString getValsDecoder getValsCallData
                    |> Expect.equal getVals
        ]


getValsDecoder : Evm.EvmDecoder GetVals
getValsDecoder =
    Evm.evmDecode GetVals
        |> Evm.andMap Evm.uint
        |> Evm.andMap Evm.int
        |> Evm.andMap Evm.bool
        |> Evm.andMap Evm.int
        |> Evm.andMap (Evm.staticArray 2 Evm.bool)
        |> Evm.andMap (Evm.dynamicArray Evm.int)
        |> Evm.andMap Evm.string
        |> Evm.andMap (Evm.staticBytes 16)
        |> Evm.andMap (Evm.dynamicArray (Evm.staticArray 4 (Evm.staticBytes 2)))


getVals : Result String GetVals
getVals =
    let
        b2Vec =
            [ "0x1234", "0x5678", "0xffff", "0x0000" ]

        v3Val =
            BigInt.fromString
                "-999999999999999999999999999999999999999999999999999999999999999"
                |> Result.fromMaybe "Error decoding bigInt in Tests.Evm.makeGetVals"

        makeGetVals bigInt =
            { v0 = BigInt.fromInt 123
            , v1 = BigInt.fromInt -128
            , v2 = True
            , v3 = bigInt
            , v4 = [ True, False ]
            , v5 =
                [ BigInt.fromInt 1
                , BigInt.fromInt 2
                , BigInt.fromInt 3
                , bigInt
                , BigInt.fromInt -10
                , BigInt.fromInt 1
                , BigInt.fromInt 2
                , BigInt.fromInt 34
                ]
            , v6 = "wtf mate"
            , v7 = "0x31323334353637383930313233343536"
            , v8 = [ b2Vec, b2Vec, b2Vec ]
            }
    in
        Result.map makeGetVals v3Val


type alias GetVals =
    { v0 : BigInt
    , v1 : BigInt
    , v2 : Bool
    , v3 : BigInt
    , v4 : List Bool
    , v5 : List BigInt
    , v6 : String
    , v7 : String
    , v8 : List (List String)
    }


getValsCallData : String
getValsCallData =
    "0x000000000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff800000000000000000000000000000000000000000000000000000000000000001fffffffffffd91b2cf1333cdea2270cea82d81dc5342301980000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000260313233343536373839303132333435360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a00000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003fffffffffffd91b2cf1333cdea2270cea82d81dc534230198000000000000001fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff60000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000008777466206d617465000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312340000000000000000000000000000000000000000000000000000000000005678000000000000000000000000000000000000000000000000000000000000ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012340000000000000000000000000000000000000000000000000000000000005678000000000000000000000000000000000000000000000000000000000000ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012340000000000000000000000000000000000000000000000000000000000005678000000000000000000000000000000000000000000000000000000000000ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
