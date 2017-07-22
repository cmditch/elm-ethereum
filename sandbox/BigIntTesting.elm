module BigIntTesting exposing (..)

import Json.Decode as Decode exposing (Decoder, string)
import BigInt exposing (BigInt(..))
import String.Extra exposing (leftOf)


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


testList : List String
testList =
    [ withAll, withoutE, withoutPeriod, withoutAll, negWithAll, negWithoutE, negWithoutPeriod, negWithoutAll ]


decodedList : List (Result String BigInt.BigInt)
decodedList =
    testList
        |> List.map (Decode.decodeString bigIntDecoder)



-- isListOk : Bool
-- isListOk =
--     decodedList


bigIntDecoder : Decoder BigInt
bigIntDecoder =
    let
        removeENotation =
            leftOf "e" >> String.filter (\c -> c /= '.')

        convert stringyBigInt =
            case stringyBigInt |> BigInt.fromString of
                Just bigint ->
                    Decode.succeed bigint

                Nothing ->
                    Decode.fail "Error decoding BigInt"
    in
        string |> Decode.andThen (removeENotation >> convert)
