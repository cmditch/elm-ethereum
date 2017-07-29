module Web3.Decoders
    exposing
        ( expectInt
        , expectString
        , expectBool
        , expectJson
        , expectBigInt
        , bigIntDecoder
        )

import Web3.Internal exposing (expectStringResponse)
import Web3.Types exposing (Expect)
import Json.Decode as Decode exposing (int, string, bool, Decoder)
import BigInt exposing (BigInt)


expectInt : Expect Int
expectInt =
    expectStringResponse (\r -> Decode.decodeString int r)


expectString : Expect String
expectString =
    expectStringResponse (\r -> Decode.decodeString string r)


expectBool : Expect Bool
expectBool =
    expectStringResponse (\r -> Decode.decodeString bool r)


expectJson : Decoder a -> Expect a
expectJson decoder =
    expectStringResponse (\r -> Decode.decodeString decoder r)


expectBigInt : Expect BigInt
expectBigInt =
    expectStringResponse (\r -> Decode.decodeString bigIntDecoder r)


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
