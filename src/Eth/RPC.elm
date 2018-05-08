module Eth.RPC
    exposing
        ( RpcRequest
        , toTask
        , toHttpBody
        )

{-| Json RPC Helpers
@docs RpcRequest, toTask, toHttpBody
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value, object, int, string, list)
import Task exposing (Task)
import Http


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
    Http.post url (rpcBody 1 method params) (Decode.field "result" decoder)
        |> Http.toTask


{-| -}
toHttpBody : Int -> String -> List Value -> Http.Body
toHttpBody id method params =
    encode id method params
        |> Http.jsonBody


encode : Int -> String -> List Value -> Value
encode id method params =
    object
        [ ( "id", int id )
        , ( "method", string method )
        , ( "params", list params )
        ]
