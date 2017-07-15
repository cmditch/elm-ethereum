module Web3.Internal
    exposing
        ( Expect
        , expectInt
        , expectStringResponse
        )


type alias Response =
    String


type Expect a
    = Expect


expectInt : Expect Int
expectInt =
    expectStringResponse (\r -> String.toInt r)


expectStringResponse : (Response -> Result String a) -> Expect a
expectStringResponse =
    Native.Web3.expectStringResponse
