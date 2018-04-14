module Web3.Internal.Utils exposing (..)

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
