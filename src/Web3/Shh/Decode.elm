module Web3.Shh.Decode exposing (..)

import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (required, decode, custom, optional)
import Web3.Shh.Types exposing (..)

