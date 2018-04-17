module Web3.RPC exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value, object, int, string, list)
import Task exposing (Task)
import Http


type alias RpcRequest a =
    { url : String
    , method : String
    , params : List Value
    , decoder : Decoder a
    }


buildRequest : RpcRequest a -> Task Http.Error a
buildRequest { url, method, params, decoder } =
    Http.post url (defaultRPCBody method params) (Decode.field "result" decoder)
        |> Http.toTask


defaultRPCBody : String -> List Value -> Http.Body
defaultRPCBody =
    rpcBody 1


rpcBody : Int -> String -> List Value -> Http.Body
rpcBody id method params =
    encodeRPC id method params
        |> Http.jsonBody


encodeRPC : Int -> String -> List Value -> Value
encodeRPC id method params =
    object
        [ ( "id", int id )
        , ( "method", string method )
        , ( "params", list params )
        ]