module Web3.Internal
    exposing
        ( Request
        , EventRequest
        , expectStringResponse
        , constructOptions
        , decapitalize
        )

import Json.Encode as Encode exposing (Value)
import Web3.Types exposing (..)


type alias Request a =
    { method : String
    , params : Encode.Value
    , expect : Expect a
    , callType : CallType
    , applyScope : Maybe String
    }


type alias EventRequest =
    { abi : Abi
    , address : Address
    , argsFilter : Value
    , filterParams : Value
    , eventName : String
    }


expectStringResponse : (String -> Result String a) -> Expect a
expectStringResponse =
    Native.Web3.expectStringResponse


decapitalize : String -> String
decapitalize string =
    (String.left 1 string |> String.toLower) ++ (String.dropLeft 1 string)


constructOptions : List ( String, Maybe String ) -> String
constructOptions options =
    options
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault "" v ))
        |> List.map (\( k, v ) -> k ++ ": " ++ v ++ ",")
        |> String.join ""
        |> String.dropRight 1
