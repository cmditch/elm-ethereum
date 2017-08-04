module Web3.LowLevel exposing (..)

-- import Web3.Eth.Types exposing (..)
-- import Web3.Types exposing (..)

import Web3.Internal exposing (..)


eventWatch : EventRequest -> Sub msg
eventWatch =
    Native.Web3.eventWatch
