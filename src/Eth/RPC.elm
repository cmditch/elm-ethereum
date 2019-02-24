module Eth.RPC exposing
    ( RpcRequest, toTask
    , encode, toHttpBody
    )

{-| Json RPC Helpers

@docs RpcRequest, toTask


# Low Level

@docs encode, toHttpBody

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value, int, list, object, string)
import Task exposing (Task)


jsonRPCVersion : String
jsonRPCVersion =
    "2.0"


{-| -}
type alias RpcRequest a =
    { url : String
    , method : String
    , params : List Value
    , decoder : Decoder a
    }


{-| -}
toTask : RpcRequest a -> Task Http.Error a
toTask { url, method, params, decoder } =
    Http.task
        { method = "POST"
        , headers = []
        , url = url
        , body = toHttpBody 1 method params
        , resolver = Http.stringResolver (expectJson decoder)
        , timeout = Nothing
        }



-- Http.post url (toHttpBody 1 method params) (Decode.field "result" decoder)
--     |> Http.toTask


expectJson : Decoder a -> Http.Response String -> Result Http.Error a
expectJson decoder response =
    case response of
        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError

        Http.BadStatus_ metadata body ->
            Err (Http.BadStatus metadata.statusCode)

        Http.GoodStatus_ metadata body ->
            case Decode.decodeString (Decode.field "result" decoder) body of
                Ok value ->
                    Ok value

                Err err ->
                    Err (Http.BadBody (Decode.errorToString err))



-- Low Level


{-| -}
toHttpBody : Int -> String -> List Value -> Http.Body
toHttpBody id method params =
    encode id method params
        |> Http.jsonBody


{-| -}
encode : Int -> String -> List Value -> Value
encode id method params =
    object
        [ ( "id", int id )
        , ( "jsonrpc", string jsonRPCVersion )
        , ( "method", string method )
        , ( "params", list identity params )
        ]
