module AddressBenchmark exposing (main)

import Benchmark exposing (..)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import Eth.Utils as Eth
import Eth.Defaults exposing (zeroAddress)


main : BenchmarkProgram
main =
    program <|
        describe "Address"
            [ toAddress, addressToString ]


toAddress : Benchmark
toAddress =
    describe "toAddress"
        [ benchmark1 "from lowercase" Eth.toAddress "0xf85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
        , benchmark1 "from uppercase" Eth.toAddress "0XF85FEEA2FDD81D51177F6B8F35F0E6734CE45F5F"
        , benchmark1 "from evm" Eth.toAddress "000000000000000000000000f85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
        , benchmark1 "from already checksummed" Eth.toAddress "e4219dc25D6a05b060c2a39e3960A94a214aAeca"
        , benchmark1 "invalid from evm" Eth.toAddress "000000000000000100000000f85feea2fdd81d51177f6b8f35f0e6734ce45f5f"
        , benchmark1 "invalid checksum" Eth.toAddress "e4219dc25D6a05b060c2a39e3960a94a214aAeca"
        , benchmark1 "invalid hex" Eth.toAddress "e4219dc25D6a05b060c2a39e3960A94a214aAeKa"
        , benchmark1 "invalid size" Eth.toAddress "e4219dc25D6a05b060c2a39e3960A94a214aAeKas"
        ]


addressToString : Benchmark
addressToString =
    describe "addressToString"
        [ benchmark1 "" Eth.addressToString zeroAddress
        ]
