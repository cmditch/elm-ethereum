module Web3.Decoders exposing (bigIntDecoder, expectInt, expectJson)

import Web3.Internal exposing (expectStringResponse)
import Web3.Types exposing (Expect)
import Json.Decode as Decode exposing (string, Decoder)
import BigInt exposing (BigInt)


bigIntDecoder : Decoder BigInt
bigIntDecoder =
    let
        convert stringyBigInt =
            case stringyBigInt |> BigInt.fromString of
                Just bigint ->
                    Decode.succeed bigint

                Nothing ->
                    Decode.fail "Error decoding BigInt"
    in
        string |> Decode.andThen convert


expectInt : Expect Int
expectInt =
    expectStringResponse (\r -> String.toInt r)


expectJson : Decoder a -> Expect a
expectJson decoder =
    expectStringResponse (\r -> Decode.decodeString decoder r)
