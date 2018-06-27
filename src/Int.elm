module Int exposing (..)

import BigInt exposing (BigInt)
import String.Extra as StringExtra


-- Tests


test : Bool
test =
    List.map runTest testCases
        |> List.all ((==) True)


runTest : ( String, String ) -> Bool
runTest ( stringyInt, hexyInt ) =
    decodeInt hexyInt
        |> Maybe.map BigInt.toString
        |> Maybe.map ((==) stringyInt)
        |> Maybe.withDefault False


testCases : List ( String, String )
testCases =
    [ ( "4096", "0x1000" )
    , ( "0", "0x0000000000000000000000000000000000000000000000000000000000000000" )
    , ( "1", "0x0000000000000000000000000000000000000000000000000000000000000001" )
    , ( "-1", "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff" )
    , ( "2", "0x0000000000000000000000000000000000000000000000000000000000000002" )
    , ( "-2", "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe" )
    , ( "10", "0x000000000000000000000000000000000000000000000000000000000000000a" )
    , ( "-10", "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6" )
    , ( "11", "0x000000000000000000000000000000000000000000000000000000000000000b" )
    , ( "-11", "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5" )
    , ( "127", "0x000000000000000000000000000000000000000000000000000000000000007f" )
    , ( "-127", "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff81" )
    , ( "-128", "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff80" )
    , ( "32767", "0x0000000000000000000000000000000000000000000000000000000000007fff" )
    , ( "-32767", "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8001" )
    , ( "-32768", "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8000" )
    , ( "57896044618658097711785492504343953926634992332820282019728792003956564819967", "0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff" )
    , ( "-57896044618658097711785492504343953926634992332820282019728792003956564819968", "0x8000000000000000000000000000000000000000000000000000000000000000" )
    ]



-- First pass at implementation


decodeInt : String -> Maybe BigInt
decodeInt str =
    if isNegIntUnsafe (remove0x str) then
        remove0x str
            |> String.toList
            |> List.map toBinaryUnsafe
            |> String.join ""
            |> twosComplementUnsafe
            |> StringExtra.break 4
            |> List.map fromBinaryUnsafe
            |> String.fromList
            |> add0x
            |> String.cons '-'
            |> BigInt.fromString
    else
        BigInt.fromString str


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

                -- This part is unsafe. Assumes every char is '1' or '0'
                _ ->
                    ( accum, True )
    in
        String.foldr reducer ( "", False ) str
            |> Tuple.first



-- Internal


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
            ""


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


{-| -}
remove0x : String -> String
remove0x str =
    if String.startsWith "0x" str || String.startsWith "0X" str then
        String.dropLeft 2 str
    else
        str


{-| -}
add0x : String -> String
add0x str =
    if String.startsWith "0x" str || String.startsWith "0X" str then
        str
    else
        "0x" ++ str
