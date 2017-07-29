port module Port exposing (..)

import LightBox


port watchAdd : (LightBox.AddEvent -> msg) -> Sub msg
