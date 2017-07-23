module BigIntTesting exposing (..)

import Json.Decode as Decode exposing (Decoder, string)
import BigInt exposing (BigInt)


runTest : Bool
runTest =
    posListTest && negListTest


removeENotation : String -> String
removeENotation string =
    -- TODO Will likely not need this nifty function anymore.
    let
        removeE orig char acc =
            if char == "e" then
                acc
            else if char == "" then
                orig
            else
                removeE orig (String.right 1 acc) (String.dropRight 1 acc)
    in
        removeE string (String.right 1 string) (String.dropRight 1 string)
            |> String.filter (\c -> c /= '.')


bigIntDecoder : Decoder BigInt
bigIntDecoder =
    let
        convert stringyBigInt =
            case stringyBigInt |> BigInt.fromString of
                Just bigint ->
                    Decode.succeed bigint

                Nothing ->
                    Decode.fail "Error decoding BigInt"
    in
        string |> Decode.andThen (removeENotation >> convert)


withAll : String
withAll =
    "\"1.00389287136786176327247604509743168900146139575972864366142685224231313322991e+77\""


withoutE : String
withoutE =
    "\"1.00389287136786176327247604509743168900146139575972864366142685224231313322991\""


withoutPeriod : String
withoutPeriod =
    "\"100389287136786176327247604509743168900146139575972864366142685224231313322991e+77\""


withoutAll : String
withoutAll =
    "\"100389287136786176327247604509743168900146139575972864366142685224231313322991\""


negWithAll : String
negWithAll =
    "\"-1.00389287136786176327247604509743168900146139575972864366142685224231313322991e+77\""


negWithoutE : String
negWithoutE =
    "\"-1.00389287136786176327247604509743168900146139575972864366142685224231313322991\""


negWithoutPeriod : String
negWithoutPeriod =
    "\"-100389287136786176327247604509743168900146139575972864366142685224231313322991e+77\""


negWithoutAll : String
negWithoutAll =
    "\"-100389287136786176327247604509743168900146139575972864366142685224231313322991\""


posListTest : Bool
posListTest =
    [ negWithAll, negWithoutE, negWithoutPeriod, negWithoutAll ]
        |> List.map (Decode.decodeString bigIntDecoder)
        |> List.map testPosMaybeBigInt
        |> List.all (\a -> a == True)


negListTest : Bool
negListTest =
    [ withAll, withoutE, withoutPeriod, withoutAll ]
        |> List.map (Decode.decodeString bigIntDecoder)
        |> List.map testNegMaybeBigInt
        |> List.all (\a -> a == True)


testPosMaybeBigInt : Result error BigInt -> Bool
testPosMaybeBigInt mBigInt =
    case mBigInt of
        Ok bigInt ->
            BigInt.gt (BigInt.fromInt 0) bigInt

        Err _ ->
            False


testNegMaybeBigInt : Result error BigInt -> Bool
testNegMaybeBigInt mBigInt =
    case mBigInt of
        Ok bigInt ->
            BigInt.lt (BigInt.fromInt 0) bigInt

        Err _ ->
            False
