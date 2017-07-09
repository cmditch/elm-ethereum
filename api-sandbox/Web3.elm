module Web3 exposing (..)

import Dict exposing (..)
import Json.Decode exposing (..)


type alias Model =
    { requestMap : Dict Int (Decoder Web3Response) }


init : Model
init =
    { requestMap = Dict.empty }


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
