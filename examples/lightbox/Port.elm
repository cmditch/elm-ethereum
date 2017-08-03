port module Port exposing (..)

import Web3.Eth.Types exposing (EventLog)
import LightBox exposing (RawAddArgs)


port addPort : (EventLog RawAddArgs -> msg) -> Sub msg



-- TODO
-- We could even have code generation for the ports file.
-- npm run gen-ports
-- it would parse all the PortAndEventName types, match them up to their appropriate decoders, etc.
