module Internal.Utils exposing (..)


quote : String -> String
quote str =
    "\"" ++ str ++ "\""


toByteLength : String -> String
toByteLength str =
    if String.length str == 1 then
        String.append "0" str
    else
        str


take64 : String -> String
take64 =
    String.left 64


drop64 : String -> String
drop64 =
    String.dropLeft 64


leftPadTo64 : String -> String
leftPadTo64 str =
    String.padLeft 64 '0' str


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
