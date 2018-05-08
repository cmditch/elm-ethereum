module Address exposing (..)

-- import Fuzz exposing (Fuzzer, int, list, string)

import Expect
import Test exposing (..)
import Eth.Utils as Eth
import Internal.Types as Internal


toAddressTests : Test
toAddressTests =
    describe "toAddress"
        [ describe "toAddress success"
            [ test "from lowercase address with 0x" <|
                \_ ->
                    Eth.toAddress "0xe4219dc25d6a05b060c2a39e3960a94a214aaeca"
                        |> Expect.equal (Ok <| Internal.Address "e4219dc25d6a05b060c2a39e3960a94a214aaeca")
            , test "from uppercase address with 0x" <|
                \_ ->
                    Eth.toAddress "0XF85FEEA2FDD81D51177F6B8F35F0E6734CE45F5F"
                        |> Expect.equal (Ok <| Internal.Address "f85feea2fdd81d51177f6b8f35f0e6734ce45f5f")
            , test "from evm" <|
                \_ ->
                    Eth.toAddress "000000000000000000000000f85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
                        |> Expect.equal (Ok <| Internal.Address "f85feea2fdd81d51177f6b8f35f0e6734ce45f5f")
            , test "from already checksummed" <|
                \_ ->
                    Eth.toAddress "0xe4219dc25D6a05b060c2a39e3960A94a214aAeca"
                        |> Expect.equal (Ok <| Internal.Address "e4219dc25d6a05b060c2a39e3960a94a214aaeca")
            , test "addressToString" <|
                \_ ->
                    Eth.toAddress "0XF85FEEA2FDD81D51177F6B8F35F0E6734CE45F5F"
                        |> Result.map Eth.addressToString
                        |> Expect.equal (Ok "0xf85fEea2FdD81d51177F6b8F35F0e6734Ce45F5F")
            ]
        , describe "toAddress fails"
            [ test "from short address with 0x" <|
                \_ ->
                    Eth.toAddress "0x4219dc25d6a05b060c2a39e3960a94a214aaeca"
                        |> Expect.err
            , test "from short address without 0x" <|
                \_ ->
                    Eth.toAddress "4219dc25d6a05b060c2a39e3960a94a214aaeca"
                        |> Expect.err
            , test "from invalid char evm" <|
                \_ ->
                    Eth.toAddress
                        "000000010000000000000000f85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
                        |> Expect.err
            , test "from invalid length evm" <|
                \_ ->
                    Eth.toAddress
                        "00000000000000000000000f85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
                        |> Expect.err
            , test "from invalid checksummed" <|
                \_ ->
                    Eth.toAddress "0xe4219dc25D6a05b060c2a39e3960a94a214aAeca"
                        |> Expect.err
            ]
        ]
