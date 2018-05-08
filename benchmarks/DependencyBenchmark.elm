module DependencyBenchmark exposing (main)

import Benchmark exposing (..)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import Keccak exposing (ethereum_keccak_256)


main : BenchmarkProgram
main =
    program <|
        describe "Dependencies"
            [ keccak ]


keccak : Benchmark
keccak =
    describe "keccak_256"
        [ benchmark1 "10 Int array" ethereum_keccak_256 [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
        , benchmark1 "empty array" ethereum_keccak_256 []
        ]
