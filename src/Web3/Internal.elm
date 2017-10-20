module Web3.Internal
    exposing
        ( Request
        , Expect
        , CallType(..)
        , expectStringResponse
        , constructOptions
        , decapitalize
        , toTask
        )

import Json.Encode as Encode exposing (Value)
import Native.Web3
import Web3.Types exposing (..)
import Task exposing (Task)


type alias Request a =
    { method : String
    , params : Encode.Value
    , expect : Expect a
    , callType : CallType
    , applyScope : Maybe String
    }


type Expect a
    = Expect


type CallType
    = Sync
    | Async
    | Getter
    | CustomSync String


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


expectStringResponse : (String -> Result String a) -> Expect a
expectStringResponse =
    Native.Web3.expectStringResponse


toTask : Request a -> Task Error a
toTask request =
    Native.Web3.toTask (evalHelper request) request


evalHelper : Request a -> String
evalHelper request =
    let
        applyScope =
            case request.applyScope of
                Just scope ->
                    scope

                Nothing ->
                    "null"

        callType =
            case request.callType of
                Async ->
                    ".apply(" ++ applyScope ++ ", request.params.concat(web3Callback))"

                Sync ->
                    ".apply(" ++ applyScope ++ ", request.params)"

                CustomSync _ ->
                    ".apply(" ++ applyScope ++ ", request.params)"

                Getter ->
                    ""
    in
        "web3."
            ++ request.method
            ++ callType
