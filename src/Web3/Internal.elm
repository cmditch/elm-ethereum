module Web3.Internal
    exposing
        ( Expect
        , expectStringResponse
        , expectInt
        , expectJson
        )

import Json.Decode as Decode exposing (Decoder)


type alias Response =
    String


type Expect a
    = Expect


expectStringResponse : (Response -> Result String a) -> Expect a
expectStringResponse =
    Native.Web3.expectStringResponse


expectInt : Expect Int
expectInt =
    expectStringResponse (\r -> String.toInt r)


expectJson : Decoder a -> Expect a
expectJson decoder =
    expectStringResponse (\r -> Decode.decodeString decoder r)
