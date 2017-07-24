module Web3.Decoders exposing (expectInt, expectString, expectJson, bigIntDecoder)

import Web3.Internal exposing (expectStringResponse)
import Web3.Types exposing (Expect)
import Json.Decode as Decode exposing (int, string, Decoder)
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
    expectStringResponse (\r -> Decode.decodeString int r)


expectJson : Decoder a -> Expect a
expectJson decoder =
    expectStringResponse (\r -> Decode.decodeString decoder r)


expectString : Expect String
expectString =
    expectStringResponse (\r -> Decode.decodeString string r)
