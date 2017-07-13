port module Web3
    exposing
        ( Request
        , Response
        , Model(..)
        , init
        , handleResponse
        , request
        , response
        )

import Dict exposing (Dict)


type Model msg
    = Model Int (Dict Int (String -> msg))


type alias Request =
    { func : String
    , args : List String
    , id : Int
    }


type alias Response =
    { id : Int
    , data : String
    }


init : Model msg
init =
    Model 0 Dict.empty


handleResponse : Model msg -> Int -> Maybe (String -> msg)
handleResponse (Model counter dict) id =
    Dict.get id dict


port request : Request -> Cmd msg


port response : (Response -> msg) -> Sub msg
