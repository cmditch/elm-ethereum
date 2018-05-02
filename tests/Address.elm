module Address exposing (..)

-- import Fuzz exposing (Fuzzer, int, list, string)

import Expect
import Test exposing (..)
import Web3.Utils as Web3


toAddressTests : Test
toAddressTests =
    describe "toAddress"
        [ describe "toAddress success"
            [ test "from lowercase address with 0x" <|
                \_ ->
                    Web3.toAddress "0xe4219dc25d6a05b060c2a39e3960a94a214aaeca"
                        |> Result.map Web3.addressToString
                        |> Expect.equal (Ok "0xe4219dc25d6a05b060c2a39e3960a94a214aaeca")
            , test "from uppercase address with 0x" <|
                \_ ->
                    Web3.toAddress "0XF85FEEA2FDD81D51177F6B8F35F0E6734CE45F5F"
                        |> Result.map Web3.addressToString
                        |> Expect.equal (Ok "0xf85feea2fdd81d51177f6b8f35f0e6734ce45f5f")
            , test "from evm" <|
                \_ ->
                    Web3.toAddress "000000000000000000000000f85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
                        |> Result.map Web3.addressToString
                        |> Expect.equal (Ok "0xf85feea2fdd81d51177f6b8f35f0e6734ce45f5f")
            , test "from already checksummed" <|
                \_ ->
                    Web3.toAddress "0xe4219dc25D6a05b060c2a39e3960A94a214aAeca"
                        |> Result.map Web3.addressToString
                        |> Expect.equal (Ok "0xe4219dc25D6a05b060c2a39e3960A94a214aAeca")
            ]
        , describe "toAddress fails"
            [ test "from short address without 0x" <|
                \_ ->
                    Web3.toAddress "4219dc25d6a05b060c2a39e3960a94a214aaeca"
                        |> Expect.err
            , test "from invalid char evm" <|
                \_ ->
                    Web3.toAddress
                        "000000010000000000000000f85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
                        |> Expect.err
            , test "from invalid length evm" <|
                \_ ->
                    Web3.toAddress
                        "00000000000000000000000f85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
                        |> Expect.err
            , test "from invalid checksummed" <|
                \_ ->
                    Web3.toAddress "0xe4219dc25D6a05b060c2a39e3960a94a214aAeca"
                        |> Expect.err
            ]
        ]
