port module Port exposing (..)

import Web3.Eth.Types exposing (EventLog)
import LightBox exposing (RawAddArgs)


port watchAdd : (EventLog RawAddArgs -> msg) -> Sub msg
