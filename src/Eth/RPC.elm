module Eth.RPC
    exposing
        ( RpcRequest
        , toTask
        , toHttpBody
        , encode
        )

{-| Json RPC Helpers
@docs RpcRequest, toTask


# Low Level

@docs encode, toHttpBody

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value, object, int, string, list)
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
    Http.post url (toHttpBody 1 method params) (Decode.field "result" decoder)
        |> Http.toTask



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
        , ( "params", list params )
        ]
