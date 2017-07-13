module Web3.Decoders exposing (bigIntDecoder)

import Json.Decode as Decode exposing (string, Decoder)
import BigInt exposing (BigInt)


bigIntDecoder : Decoder BigInt
bigIntDecoder =
    let
        convert stringyBigInt =
            case BigInt.fromString stringyBigInt of
                Just bigint ->
                    Decode.succeed bigint

                Nothing ->
                    Decode.fail "Error decoding BigInt"
    in
        string |> Decode.andThen convert
