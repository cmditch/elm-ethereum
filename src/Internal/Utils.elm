module Internal.Utils exposing (..)

import Json.Encode as Encode exposing (Value)


quote : String -> String
quote str =
    "\"" ++ str ++ "\""


listOfMaybesToVal : List ( String, Maybe Value ) -> Value
listOfMaybesToVal keyValueList =
    keyValueList
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault Encode.null v ))
        |> Encode.object


toByteLength : String -> String
toByteLength s =
    if String.length s == 1 then
        String.append "0" s
    else
        s


take64 : String -> String
take64 =
    String.left 64


drop64 : String -> String
drop64 =
    String.dropLeft 64


leftPad : String -> String
leftPad data =
    String.padLeft 64 '0' data


{-| -}
add0x : String -> String
add0x str =
    if String.startsWith "0x" str || String.startsWith "0X" str then
        str
    else
        "0x" ++ str


{-| -}
remove0x : String -> String
remove0x str =
    if String.startsWith "0x" str || String.startsWith "0X" str then
        String.dropLeft 2 str
    else
        str
