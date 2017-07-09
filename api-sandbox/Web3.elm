port module Web3
    exposing
        ( Model
        , Request
        , Response
        , init
        , handleResponse
        , getBlockNumber
        , request
        , response
        )

import Dict exposing (..)
import Json.Decode exposing (..)


init : Model msg
init =
    Model Dict.empty


type Model msg
    = Model (Dict Int (String -> msg))


type alias Request =
    { func : String
    , args : List String
    , id : Int
    }


type alias Response =
    { id : Int
    , result : String
    }


handleResponse : Model msg -> Int -> Maybe (String -> msg)
handleResponse (Model state) id =
    Dict.get id state


getBlockNumber : Model msg -> (String -> msg) -> ( Model msg, Cmd msg )
getBlockNumber (Model state) msg =
    let
        id =
            1

        state_ =
            Dict.insert id msg state
    in
        ( Model state_
        , request
            { func = "eth.getBlockNumber"
            , args = []
            , id = id
            }
        )


port request : Request -> Cmd msg


port response : (Response -> msg) -> Sub msg
