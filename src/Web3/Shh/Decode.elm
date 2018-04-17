module Web3.Shh.Decode exposing (whisperId)

import Json.Decode as Decode exposing (string, Decoder)
import Web3.Shh.Types exposing (WhisperId)
import Web3.Internal.Types as Internal
import Web3.Decode exposing (resultToDecoder)
import Web3.Utils exposing (isHex)


whisperId : Decoder WhisperId
whisperId =
    resultToDecoder toWhisperId


toWhisperId : String -> Result String WhisperId
toWhisperId str =
    case isHex str && String.length str == 122 of
        True ->
            Ok <| Internal.WhisperId str

        False ->
            Err <| "Couldn't convert " ++ str ++ "into whisper id"
