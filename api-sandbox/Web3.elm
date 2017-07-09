port module Web3
    exposing
        ( Web3State
        , Request
        , Response
        , init
        , getBlockNumber
        , request
        , response
        )

import Dict exposing (..)
import Json.Decode exposing (..)


init : Web3State msg
init =
    Web3State Dict.empty


type Web3State msg
    = Web3State (Dict Int (String -> msg))


type Web3Response
    = Block Int


type alias Request =
    { func : String
    , args : List String
    , id : Int
    }


type alias Response =
    String


type Web3Function
    = Basic BasicFunction
    | Eth EthFunction


type BasicFunction
    = ToWei
    | FromWei


type EthFunction
    = GetBlockNumber


getBlockNumber : Web3State msg -> (String -> msg) -> ( Web3State msg, Cmd msg )
getBlockNumber (Web3State state) msg =
    let
        id =
            1

        state_ =
            Dict.insert id msg state
    in
        ( Web3State state_
        , request
            { func = "eth.getBlockNumber"
            , args = []
            , id = id
            }
        )


port request : Request -> Cmd msg


port response : (Response -> msg) -> Sub msg
