port module Port exposing (..)

import LightBox


port watchAdd : (LightBox.RawAddEvent -> msg) -> Sub msg
