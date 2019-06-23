module Eth.Abi.Int exposing (fromBinaryUnsafe, fromString, isNegIntUnsafe, toBinaryUnsafe, toString, twosComplementUnsafe)

import BigInt exposing (BigInt)
import Eth.Utils exposing (add0x, remove0x)
import String.Extra as StringExtra


fromString : String -> Maybe BigInt
fromString str =
    let
        no0x =
            remove0x str
    in
    if isNegIntUnsafe no0x then
        no0x
            |> String.toList
            |> List.map toBinaryUnsafe
            |> String.join ""
            |> twosComplementUnsafe
            |> StringExtra.break 4
            |> List.map fromBinaryUnsafe
            |> String.fromList
            |> add0x
            |> String.cons '-'
            |> BigInt.fromHexString

    else
        BigInt.fromHexString (add0x str)


toString : BigInt -> String
toString num =
    let
        ( xs_, twosComplementOrNotTwosComplement ) =
            case BigInt.toHexString num |> String.toList of
                '-' :: xs ->
                    ( xs, twosComplementUnsafe >> String.padLeft 256 '1' )

                xs ->
                    ( xs, String.padLeft 256 '0' )
    in
    List.map toBinaryUnsafe xs_
        |> String.join ""
        |> twosComplementOrNotTwosComplement
        |> StringExtra.break 4
        |> List.map fromBinaryUnsafe
        |> String.fromList


{-| Bit-Flip-Fold-Holla-for-a-Dolla

The string is folded from the right.
When the first '1' is encountered, all remaining bits are flipped

e.g.
Input: "1000100"
Output: "0111100"

-}
twosComplementUnsafe : String -> String
twosComplementUnsafe str =
    let
        reducer char ( accum, isFlipping ) =
            case ( char, isFlipping ) of
                ( '0', False ) ->
                    ( String.cons '0' accum, False )

                ( '0', True ) ->
                    ( String.cons '1' accum, True )

                -- Flip to True when encountering first '1'
                ( '1', False ) ->
                    ( String.cons '1' accum, True )

                ( '1', True ) ->
                    ( String.cons '0' accum, True )

                -- This is the unsafe part. Assumes every char is '1' or '0'
                _ ->
                    ( accum, True )
    in
    String.foldr reducer ( "", False ) str
        |> Tuple.first


toBinaryUnsafe : Char -> String
toBinaryUnsafe char =
    case char of
        '0' ->
            "0000"

        '1' ->
            "0001"

        '2' ->
            "0010"

        '3' ->
            "0011"

        '4' ->
            "0100"

        '5' ->
            "0101"

        '6' ->
            "0110"

        '7' ->
            "0111"

        '8' ->
            "1000"

        '9' ->
            "1001"

        'a' ->
            "1010"

        'b' ->
            "1011"

        'c' ->
            "1100"

        'd' ->
            "1101"

        'e' ->
            "1110"

        'f' ->
            "1111"

        _ ->
            "error converting hex to binary"


fromBinaryUnsafe : String -> Char
fromBinaryUnsafe str =
    case str of
        "0000" ->
            '0'

        "0001" ->
            '1'

        "0010" ->
            '2'

        "0011" ->
            '3'

        "0100" ->
            '4'

        "0101" ->
            '5'

        "0110" ->
            '6'

        "0111" ->
            '7'

        "1000" ->
            '8'

        "1001" ->
            '9'

        "1010" ->
            'a'

        "1011" ->
            'b'

        "1100" ->
            'c'

        "1101" ->
            'd'

        "1110" ->
            'e'

        "1111" ->
            'f'

        _ ->
            '!'


isNegIntUnsafe : String -> Bool
isNegIntUnsafe str =
    case String.left 1 str of
        "0" ->
            False

        "1" ->
            False

        "2" ->
            False

        "3" ->
            False

        "4" ->
            False

        "5" ->
            False

        "6" ->
            False

        "7" ->
            False

        "8" ->
            True

        "9" ->
            True

        "a" ->
            True

        "b" ->
            True

        "c" ->
            True

        "d" ->
            True

        "e" ->
            True

        "f" ->
            True

        _ ->
            False
