module Web3.Decode exposing (resultToDecoder, hexInt)

import Json.Decode as Decode exposing (Decoder)
import Hex
import Web3.Utils exposing (remove0x)


resultToDecoder : (String -> Result String a) -> Decoder a
resultToDecoder strToResult =
    let
        convert n =
            case strToResult n of
                Ok val ->
                    Decode.succeed val

                Err error ->
                    Decode.fail error
    in
        Decode.string |> Decode.andThen convert


hexInt : Decoder Int
hexInt =
    resultToDecoder (remove0x >> Hex.fromString)
