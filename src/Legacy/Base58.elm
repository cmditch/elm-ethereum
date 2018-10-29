module Legacy.Base58 exposing (decode, encode)

{-| Handles encoding/decoding base58 data


# Transformations

@docs decode, encode

-}

import Array exposing (Array)
import BigInt exposing (BigInt)
import String


alphabet : String
alphabet =
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


alphabetArr : Array Char
alphabetArr =
    alphabet
        |> String.toList
        |> Array.fromList


alphabetLength : BigInt
alphabetLength =
    BigInt.fromInt (String.length alphabet)


getIndex : Char -> Result String BigInt
getIndex char =
    String.indexes (String.fromChar char) alphabet
        |> List.head
        |> Result.fromMaybe ("'" ++ String.fromChar char ++ "' is not a valid base58 character.")
        |> Result.map BigInt.fromInt


{-| Decodes a string into a BigInt

    "ANYBx47k26vP81XFbQXh6XKUj7ptQRJMLt"
        |> Base58.decode
        |> Result.toMaybe
        == BigInt.fromString "146192635802076751054841979942155177482410195601230638449945"

-}
decode : String -> Result String BigInt
decode str =
    let
        strList =
            String.toList str

        ( _, decodedResult ) =
            List.foldr
                (\letter ( multi, dec ) ->
                    let
                        result =
                            getIndex letter
                                |> Result.map (BigInt.mul multi)
                                |> Result.andThen (\n -> Result.map (BigInt.add n) dec)

                        mul =
                            BigInt.mul multi alphabetLength
                    in
                    ( mul, result )
                )
                ( BigInt.fromInt 1, Ok (BigInt.fromInt 0) )
                strList
    in
    if str == "" then
        Err "An empty string is not valid base58"

    else
        decodedResult


{-| Encodes a BigInt into a string

    BigInt.fromString "146192635802076751054841979942155177482410195601230638449945"
        |> Maybe.map Base58.encode
        == Ok "ANYBx47k26vP81XFbQXh6XKUj7ptQRJMLt"

-}
encode : BigInt -> String
encode num =
    let
        ( _, encoded ) =
            encodeReduce num ( "", BigInt.fromInt 0 )
    in
    encoded


encodeReduce : BigInt -> ( String, BigInt ) -> ( BigInt, String )
encodeReduce num ( encoded, n ) =
    if BigInt.gte num alphabetLength then
        let
            dv =
                BigInt.div num alphabetLength

            md =
                BigInt.sub num (BigInt.mul alphabetLength dv)

            index =
                Maybe.withDefault 0 (String.toInt (BigInt.toString md))

            i =
                String.fromChar (Maybe.withDefault '0' (Array.get index alphabetArr))

            newEncoded =
                i ++ encoded
        in
        encodeReduce dv ( newEncoded, dv )

    else
        let
            index =
                Maybe.withDefault 0 (String.toInt (BigInt.toString num))

            i =
                String.fromChar (Maybe.withDefault '0' (Array.get index alphabetArr))

            newEncoded =
                i ++ encoded
        in
        ( BigInt.fromInt 0, newEncoded )
