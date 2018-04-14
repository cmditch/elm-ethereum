module AddressBenchmark exposing (main)

import Benchmark exposing (..)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import Web3.Utils as Web3
import Web3.Constants exposing (zeroAddress)


main : BenchmarkProgram
main =
    program <|
        describe "Address"
            [ toAddress, addressToString ]


toAddress : Benchmark
toAddress =
    describe "toAddress"
        [ benchmark1 "from lowercase" Web3.toAddress "0xf85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
        , benchmark1 "from already checksummed" Web3.toAddress "e4219dc25D6a05b060c2a39e3960A94a214aAeca"
        , benchmark1 "invalid hex" Web3.toAddress "e4219dc25D6a05b060c2a39e3960A94a214aAeKa"
        , benchmark1 "invalid size" Web3.toAddress "e4219dc25D6a05b060c2a39e3960A94a214aAeKas"
        ]


addressToString : Benchmark
addressToString =
    describe "addressToString"
        [ benchmark1 "" Web3.addressToString zeroAddress
        ]
