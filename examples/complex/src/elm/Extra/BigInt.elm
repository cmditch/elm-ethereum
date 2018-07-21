module Extra.BigInt exposing (..)

import BigInt exposing (BigInt)


countDownFrom : BigInt -> List BigInt
countDownFrom num =
    let
        countDownHelper num acc =
            case BigInt.compare num zero of
                EQ ->
                    zero :: acc

                _ ->
                    countDownHelper (BigInt.sub num one) (num :: acc)
    in
        case BigInt.lte num zero of
            True ->
                []

            False ->
                countDownHelper (BigInt.sub num one) []


zero : BigInt
zero =
    BigInt.fromInt 0


one : BigInt
one =
    BigInt.fromInt 1


{-| Allows for more accurate bigInt percentage calculations
-}
percentageOf : BigInt -> BigInt -> BigInt
percentageOf val percentage =
    let
        levelOfAccuracy =
            BigInt.fromInt 100

        expandedPercentage =
            (BigInt.fromInt 100)
                |> BigInt.mul levelOfAccuracy
    in
        BigInt.div expandedPercentage percentage
            |> BigInt.div (BigInt.mul levelOfAccuracy val)
