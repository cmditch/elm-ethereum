module Eth.Units
    exposing
        ( gwei
        , eth
        )

{-| Conversions and Helpers


# Units

@docs gwei, eth

-}

import BigInt exposing (BigInt)


{-| -}
gwei : Int -> BigInt
gwei =
    BigInt.fromInt >> BigInt.mul (BigInt.fromInt 1000000000)


{-| -}
eth : Int -> BigInt
eth =
    let
        oneEth =
            BigInt.mul (BigInt.fromInt 100) (BigInt.fromInt 10000000000000000)
    in
        BigInt.fromInt >> (BigInt.mul oneEth)
