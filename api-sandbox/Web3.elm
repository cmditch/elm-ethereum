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
        , decodeBlockNumber
        )

import Dict exposing (..)
import Json.Decode exposing (Value, string, decodeValue)


init : Model msg
init =
    Model 0 Dict.empty


type Model msg
    = Model Int (Dict Id (Value -> msg))


type alias Id =
    Int


type alias Request =
    { func : String
    , args : List String
    , id : Int
    }


type alias Response =
    { id : Int
    , data : Value
    }


handleResponse : Model msg -> Id -> Maybe (Value -> msg)
handleResponse (Model counter dict) id =
    Dict.get id dict


getBlockNumber : Model msg -> (Value -> msg) -> ( Model msg, Cmd msg )
getBlockNumber (Model counter dict) msg =
    let
        newCounter =
            counter + 1

        state_ =
            Dict.insert counter msg dict
    in
        ( Model newCounter state_
        , request
            { func = "eth.getBlockNumber"
            , args = []
            , id = counter
            }
        )


decodeBlockNumber : Value -> Result String Int
decodeBlockNumber blockNumber =
    case decodeValue string blockNumber of
        Ok blockNumber ->
            String.toInt blockNumber

        Err error ->
            Err error


port request : Request -> Cmd msg


port response : (Response -> msg) -> Sub msg
