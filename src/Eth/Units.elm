module Eth.Units exposing
    ( gwei, eth
    , EthUnit(..), toWei, fromWei, bigIntToWei
    )

{-| Conversions and Helpers


# Concise Units

Useful helpers for concise value declarations.

    txParams : Send
    txParams =
        { to = Just myContract
        , from = Nothing
        , gas = Nothing
        , gasPrice = Just (gwei 3)
        , value = Just (eth 3)
        , data = Just data
        , nonce = Nothing
        }

@docs gwei, eth


# Precise Units

Helpers for dealing with floats.

@docs EthUnit, toWei, fromWei, bigIntToWei

-}

import BigInt exposing (BigInt)
import Regex



-- fromInts, useful for building contract params


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
    BigInt.fromInt >> BigInt.mul oneEth


{-| Eth Unit
Useful for displaying to, and taking user input from, the UI
-}
type EthUnit
    = Wei
    | Kwei
    | Mwei
    | Gwei
    | Microether
    | Milliether
    | Ether
    | Kether
    | Mether
    | Gether
    | Tether


{-| Convert a given stringy EthUnit to it's Wei equivalent

    toWei Gwei "50" == Ok (BigInt.fromInt 50000000000)

    toWei Wei "40.9123" == Ok (BigInt.fromInt 40)

    toWei Kwei "40.9123" == Ok (BigInt.fromInt 40912)

    toWei Gwei "ten" == Err

-}
toWei : EthUnit -> String -> Result String BigInt
toWei unit amount =
    -- check to make sure input string is formatted correctly, should never error in here.
    if Regex.contains (Maybe.withDefault Regex.never (Regex.fromString "^\\d*\\.?\\d+$")) amount then
        let
            decimalPoints =
                decimalShift unit

            formatMantissa =
                String.slice 0 decimalPoints >> String.padRight decimalPoints '0'

            finalResult =
                case String.split "." amount of
                    [ a, b ] ->
                        a ++ formatMantissa b

                    [ a ] ->
                        a ++ formatMantissa ""

                    _ ->
                        "ImpossibleError"
        in
        case BigInt.fromIntString finalResult of
            Just result ->
                Ok result

            Nothing ->
                Err ("There was an error calculating toWei result. However, the fault is not yours; please report this bug on github. Logs: " ++ finalResult)

    else
        Err "Malformed number string passed to `toWei` method."


{-| Convert stringy Wei to a given EthUnit

    fromWei Gwei (BigInt.fromInt 123456789) == "0.123456789"

    fromWei Ether (BigInt.fromInt 123456789) == "0.000000000123456789"

**Note** Do not pass anything larger than MAX\_SAFE\_INTEGER into BigInt.fromInt
MAX\_SAFE\_INTEGER == 9007199254740991

-}
fromWei : EthUnit -> BigInt -> String
fromWei unit amount =
    let
        decimalIndex =
            decimalShift unit

        -- There are under 10^27 wei in existance (so we safe for the next couple of millennia).
        amountStr =
            BigInt.toString amount |> String.padLeft 27 '0'

        result =
            String.left (27 - decimalIndex) amountStr
                ++ "."
                ++ String.right decimalIndex amountStr
    in
    result
        |> Regex.replace
            (Maybe.withDefault Regex.never (Regex.fromString "(^0*(?=0\\.|[1-9]))|(\\.?0*$)"))
            (\i -> "")


{-| Convert a given BigInt EthUnit to it's Wei equivalent
-}
bigIntToWei : EthUnit -> BigInt -> BigInt
bigIntToWei unit amount =
    BigInt.pow (BigInt.fromInt 10) (BigInt.fromInt <| decimalShift unit)
        |> BigInt.mul amount



-- Internal


decimalShift : EthUnit -> Int
decimalShift unit =
    case unit of
        Wei ->
            0

        Kwei ->
            3

        Mwei ->
            6

        Gwei ->
            9

        Microether ->
            12

        Milliether ->
            15

        Ether ->
            18

        Kether ->
            21

        Mether ->
            24

        Gether ->
            27

        Tether ->
            30
