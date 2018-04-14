module Address exposing (..)

-- import Fuzz exposing (Fuzzer, int, list, string)

import Expect
import Test exposing (..)
import Web3.Utils as Web3


toAddressTests : Test
toAddressTests =
    describe "toAddress"
        [ test "from lowercase address with 0x" <|
            \_ ->
                Web3.toAddress "0xe4219dc25d6a05b060c2a39e3960a94a214aaeca"
                    |> Result.map Web3.addressToString
                    |> Result.withDefault ""
                    |> Expect.equal "e4219dc25D6a05b060c2a39e3960A94a214aAeca"
        ]
