module DependencyBenchmark exposing (main)

import Abi.Int as AbiInt
import Benchmark exposing (..)
import Benchmark.Runner exposing (BenchmarkProgram, program)
import BigInt


main : BenchmarkProgram
main =
    program <|
        describe ""
            [ bigintTwosComplement
            , stringyBinaryTwosComplement
            ]


stringyBinaryTwosComplement : Benchmark
stringyBinaryTwosComplement =
    describe "stringyBinaryTwosComplement"
        [ benchmark1 "twos complement" AbiInt.toString (BigInt.fromInt 99) ]


bigintTwosComplement : Benchmark
bigintTwosComplement =
    let
        twosComplement =
            (BigInt.pow (BigInt.fromInt 2) (BigInt.fromInt 256))
    in
        describe "bigintTwosComplement"
            [ benchmark2 "twos complement" BigInt.add twosComplement (BigInt.fromInt 99) ]
