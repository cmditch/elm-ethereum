module Web3.Encode
    exposing
        ( bigInt
        , hex
        , hexInt
        )

{-| Encode rudimentary types

@docs bigInt, hex, hexInt

-}

import BigInt exposing (BigInt)
import Hex
import Json.Encode as Encode exposing (Value)
import Web3.Types exposing (..)
import Web3.Utils exposing (add0x, hexToString)


-- Encoders


{-| -}
bigInt : BigInt -> Value
bigInt =
    BigInt.toHexString >> add0x >> Encode.string


{-| -}
hex : Hex -> Value
hex =
    hexToString >> Encode.string


{-| -}
hexInt : Int -> Value
hexInt =
    Hex.toString >> add0x >> Encode.string
