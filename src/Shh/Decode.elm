module Shh.Decode
    exposing
        ( whisperId
        , toWhisperId
        )

{-| Whisper Decoders

@docs whisperId, toWhisperId

-}

import Json.Decode as Decode exposing (string, Decoder)
import Internal.Types as Internal
import Eth.Decode exposing (resultToDecoder)
import Eth.Utils exposing (isHex)
import Shh.Types exposing (WhisperId)


{-| -}
whisperId : Decoder WhisperId
whisperId =
    resultToDecoder toWhisperId


{-| -}
toWhisperId : String -> Result String WhisperId
toWhisperId str =
    case isHex str && String.length str == 122 of
        True ->
            Ok <| Internal.WhisperId str

        False ->
            Err <| "Couldn't convert " ++ str ++ "into whisper id"
