module Web3.Decoders exposing (bigIntDecoder, expectInt, expectJson)

import Web3.Internal exposing (expectStringResponse)
import Web3.Types exposing (Expect)
import Json.Decode as Decode exposing (string, Decoder)
import BigInt exposing (BigInt)


-- TODO We'll need to test the formatting of bigNumbers which removes e notation.
--  >   JSON.stringify( web3.toBigNumber("100389287136786176327247604509743168900146139575972864366142685224231313322991") )
--  <-  ""1.00389287136786176327247604509743168900146139575972864366142685224231313322991e+77""


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
