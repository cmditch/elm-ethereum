module EncodeAbi exposing (..)

import BigInt exposing (fromInt)
import Eth.Abi.Encode as E
import Eth.Types exposing (Address, Hex)
import Eth.Utils exposing (hexToString, remove0x, unsafeToAddress, unsafeToHex)
import Expect
import String exposing (join)
import String.Extra exposing (wrapWith)
import Test exposing (..)


{-| ====> ALL TESTS CASES BELOW HAVE BEEN GENERATED FROM ethersjs:
import \* as ethers from 'ethers';
const coder = new ethers.utils.AbiCoder();
function print(x: string) {
if (x.startsWith('0x')) {
x = x.substr(2);
}
let v = '';
while (x.length) {
v += x.substr(0, 64) + '",
"';
x = x.substring(64);
}
console.log(v);
}

// => see test cases

-}
uint : Int -> E.Encoding
uint =
    BigInt.fromInt >> E.uint


pointers : Test
pointers =
    describe "Pointers encoding" <|
        [ test "ok" (\_ -> Expect.pass)

        , test "Encode simple layout" <|
            \_ ->
                let
                    {-
                       print(coder.encode(
                            ['uint', 'uint'],
                            [
                                1, 2
                            ]
                        ))
                    -}
                    exp =
                        [ "0000000000000000000000000000000000000000000000000000000000000001"
                        , "0000000000000000000000000000000000000000000000000000000000000002"
                        ]
                    encoded =
                        E.abiEncodeList
                            [ uint 1
                            , uint 2
                            ]
                in
                expectHex exp encoded
        , test "Encode simple with array 1" <|
            \_ ->
                let
                    {-
                       print(coder.encode(
                            ['uint[]'],
                            [
                                [2]
                            ]
                        ))
                    -}
                    exp =
                        [ "0000000000000000000000000000000000000000000000000000000000000020"
                        , "0000000000000000000000000000000000000000000000000000000000000001"
                        , "0000000000000000000000000000000000000000000000000000000000000002"
                        ]
                    encoded =
                        E.abiEncodeList
                            [ E.list [ uint 2 ]
                            ]
                in
                expectHex exp encoded
        , test "Encode simple with array 2" <|
            \_ ->
                let
                    {-
                       print(coder.encode(
                            ['uint', 'uint[]'],
                            [
                                1, [2]
                            ]
                        ))
                    -}
                    exp =
                        [ "0000000000000000000000000000000000000000000000000000000000000001"
                        , "0000000000000000000000000000000000000000000000000000000000000040"
                        , "0000000000000000000000000000000000000000000000000000000000000001"
                        , "0000000000000000000000000000000000000000000000000000000000000002"
                        ]
                    encoded =
                        E.abiEncodeList
                            [ uint 1
                            , E.list [ uint 2 ]
                            ]
                in
                expectHex exp encoded
        , test "Encode simple with array 3" <|
            \_ ->
                let
                    {-
                       print(coder.encode(
                            ['uint', 'uint[]', 'uint'],
                            [
                                1, [2], 3
                            ]
                        ))
                    -}
                    exp =
                        [ "0000000000000000000000000000000000000000000000000000000000000001"
                        , "0000000000000000000000000000000000000000000000000000000000000060"
                        , "0000000000000000000000000000000000000000000000000000000000000003"
                        , "0000000000000000000000000000000000000000000000000000000000000001"
                        , "0000000000000000000000000000000000000000000000000000000000000002"
                        ]
                    encoded =
                        E.abiEncodeList
                            [ uint 1
                            , E.list [ uint 2 ]
                            , uint 3
                            ]
                in
                expectHex exp encoded
        , test "Encode string array" <|
            \_ ->
                let
                    {-
                       print(coder.encode(
                            ['uint', 'uint'],
                            [
                                1, 2
                            ]
                        ))
                    -}
                    exp =
                        [ "0000000000000000000000000000000000000000000000000000000000000001"
                        , "0000000000000000000000000000000000000000000000000000000000000002"
                        ]
                    encoded =
                        E.abiEncodeList
                            [ uint 1
                            , uint 2
                            ]
                in
                expectHex exp encoded
        , test "Encode muliple inline tuples in list" <|
            \_ ->
                let
                    {-
                       print(coder.encode(
                            ['uint', 'tuple(uint,uint)[]', 'uint'],
                            [
                                1, [[1,2], [3,4]], 5
                            ]
                        ))
                    -}
                    exp =
                        [ "0000000000000000000000000000000000000000000000000000000000000001" -- 1
                        , "0000000000000000000000000000000000000000000000000000000000000060" -- pointer to array
                        , "0000000000000000000000000000000000000000000000000000000000000005" -- 5
                        -- array body
                        , "0000000000000000000000000000000000000000000000000000000000000002" -- array len
                        , "0000000000000000000000000000000000000000000000000000000000000001" -- elt 1 (part 1)
                        , "0000000000000000000000000000000000000000000000000000000000000002" -- elt 1 (part 2)
                        , "0000000000000000000000000000000000000000000000000000000000000003" -- elt 2 (part 1)
                        , "0000000000000000000000000000000000000000000000000000000000000004" -- elt 2 (part 2)
                        ]
                    encoded =
                        E.abiEncodeList
                            [ uint 1
                            , E.list
                                [ E.tuple [ uint 1, uint 2 ]
                                , E.tuple [ uint 3, uint 4 ]
                                ]
                            , uint 5
                            ]
                in
                expectHex exp encoded
        , test "Encode muliple complex tuples in list" <|
            \_ ->
                let
                    {-
                       print(coder.encode(
                           ['uint', 'tuple(uint,string)[]', 'uint'],
                           [
                               1, [[2,'some data'], [3,'other data']], 4
                           ]
                       ))
                    -}
                    exp =
                        [ "0000000000000000000000000000000000000000000000000000000000000001" -- 1
                        , "0000000000000000000000000000000000000000000000000000000000000060" -- pointer to array
                        , "0000000000000000000000000000000000000000000000000000000000000004" -- 4

                        -- array body
                        , "0000000000000000000000000000000000000000000000000000000000000002" -- array len
                        , "0000000000000000000000000000000000000000000000000000000000000040" -- pointer to struct 1
                        , "00000000000000000000000000000000000000000000000000000000000000c0" -- pointer to struct 2

                        -- struct 1 body
                        , "0000000000000000000000000000000000000000000000000000000000000002" -- 2
                        , "0000000000000000000000000000000000000000000000000000000000000040" -- pointer to string 1

                        -- string 1
                        , "0000000000000000000000000000000000000000000000000000000000000009" -- string len
                        , "736f6d6520646174610000000000000000000000000000000000000000000000" -- string data

                        -- struct 2 body
                        , "0000000000000000000000000000000000000000000000000000000000000003" -- 3
                        , "0000000000000000000000000000000000000000000000000000000000000040" -- pointer to string 2

                        -- string 2
                        , "000000000000000000000000000000000000000000000000000000000000000a" -- string len
                        , "6f74686572206461746100000000000000000000000000000000000000000000" -- string data
                        ]

                    encoded =
                        E.abiEncodeList
                            [ uint 1
                            , E.list
                                [ E.tuple [ uint 2, E.string "some data" ]
                                , E.tuple [ uint 3, E.string "other data" ]
                                ]
                            , uint 4
                            ]
                in
                expectHex exp encoded
        ]


someCallBody : List SomeStruct -> Result String Hex
someCallBody elts =
    let
        eltsEncoded =
            elts |> List.map encodeSubStruct |> E.list

        someToken =
            unsafeToAddress "0x0eb3a705fc54725037cc9e008bdede697f62f335"
    in
    E.abiEncodeList [ E.uint (fromInt 8), E.address someToken, eltsEncoded ]



-- struct SomeStruct {
--     bytes32 someBytes32Str;
--     address token;
--     bytes callData;
--     bool someBool;
-- }


type alias SomeStruct =
    { someBytes32Str : String
    , token : Address
    , callData : Hex
    , someBool : Bool
    }


encodeSubStruct : SomeStruct -> E.Encoding
encodeSubStruct o =
    let
        nameEncoded =
            o.someBytes32Str
                |> E.stringToHex
                |> unsafeToHex
                |> E.staticBytes
    in
    E.tuple [ nameEncoded, E.address o.token, E.bytes o.callData, E.bool o.someBool ]



complexStruct : Test
complexStruct =
    describe "Encoding complex struct"
        [ test "Encode struct with empty array" <|
            \_ ->
                let
                    encoded =
                        someCallBody []
                    expected =
                        [ "0000000000000000000000000000000000000000000000000000000000000008" -- id
                        , "0000000000000000000000000eb3a705fc54725037cc9e008bdede697f62f335" -- out otken
                        , "0000000000000000000000000000000000000000000000000000000000000060" -- array pointer
                        , "0000000000000000000000000000000000000000000000000000000000000000" -- array len
                        ]
                in
                Expect.equal (Ok (unsafeToHex <| join "" expected)) encoded
        , test "Encode struct with array elements" <|
            \_ ->
                let
                    encoded =
                        someCallBody
                            [ { someBytes32Str = "ZeroEx"
                              , token = otherToken
                              , callData = unsafeToHex "0x11111111111111111111111111111111111111111111111111111111111111112222"
                              , someBool = True
                              }
                            ]
                    expected =
                        [ "0000000000000000000000000000000000000000000000000000000000000008" -- id
                        , "0000000000000000000000000eb3a705fc54725037cc9e008bdede697f62f335" -- token
                        , "0000000000000000000000000000000000000000000000000000000000000060" -- array pointer
                        , "0000000000000000000000000000000000000000000000000000000000000001" -- array len
                        , "0000000000000000000000000000000000000000000000000000000000000020" -- first elt pointer
                        , "5a65726f45780000000000000000000000000000000000000000000000000000" -- "ZeroEx"
                        , "0000000000000000000000002170ed0880ac9a755fd29b2688956bd959f933f8" -- token
                        , "0000000000000000000000000000000000000000000000000000000000000080" -- pointer to calldata (two lines below)
                        , "0000000000000000000000000000000000000000000000000000000000000001" -- boolean "true"
                        , "0000000000000000000000000000000000000000000000000000000000000022" -- calldata len
                        , "1111111111111111111111111111111111111111111111111111111111111111" -- calldata
                        , "2222000000000000000000000000000000000000000000000000000000000000" -- calldata (part 2)
                        ]
                in
                expectHex expected encoded
        ]


coalesce : a -> Maybe a -> a
coalesce a ma =
    case ma of
        Nothing ->
            a

        Just v ->
            v


expectHex : List String -> Result String Hex -> Expect.Expectation
expectHex expected result =
    case result of
        Err e ->
            Expect.fail e

        Ok hex ->
            Expect.equal (wrapWith 64 " " <| join "" expected) (wrapWith 64 " " <| remove0x <| hexToString <| hex)


otherToken : Eth.Types.Address
otherToken =
    unsafeToAddress "0x2170ed0880ac9a755fd29b2688956bd959f933f8"



-- Abi Encoders
encodeInt : Test
encodeInt =
    describe "Int Encoding"
        [ test "-120" <|
            \_ ->
                E.abiEncode (E.int <| BigInt.fromInt -120)
                    |> Result.map Eth.Utils.hexToString
                    |> Expect.equal (Ok "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff88")
        , test "120" <|
            \_ ->
                E.abiEncode (E.int <| BigInt.fromInt 120)
                    |> Result.map Eth.Utils.hexToString
                    |> Expect.equal (Ok "0x0000000000000000000000000000000000000000000000000000000000000078")
        , test "max positive int256" <|
            \_ ->
                BigInt.fromIntString "57896044618658097711785492504343953926634992332820282019728792003956564819967"
                    |> Maybe.map (E.int >> E.abiEncode >> Result.map Eth.Utils.hexToString)
                    |> Expect.equal (Just (Ok "0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))
        , test "max negative int256" <|
            \_ ->
                BigInt.fromIntString "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
                    |> Maybe.map (E.int >> E.abiEncode >> Result.map Eth.Utils.hexToString)
                    |> Expect.equal (Just (Ok "0x8000000000000000000000000000000000000000000000000000000000000000"))
        ]

-- encodeComplex : Hex
-- encodeComplex =
--     let
--         testAddr =
--             Internal.Address "89d24a6b4ccb1b6faa2625fe562bdd9a23260359"
--         testAddr2 =
--             Internal.Address "c1cc40ccc2441d1e6170cc40a60aa35127cc6e7"
--         testAmount =
--             BigInt.fromString "0xde0b6b3a7640000"
--                 |> Maybe.withDefault (BigInt.fromInt 0)
--         zer =
--             (BigInt.fromInt 0)
--         functionSig =
--             EthUtils.functionSig "transfer(address,uint256)"
--                 |> EthUtils.hexToString
--         testBytes =
--             functionCall "transfer(address,uint256)" [ address testAddr2, uint testAmount ]
--     in
--         functionCall "propose(address,bytes,uint256)"
--             [ address testAddr, dynamicBytes testBytes, uint zer, dynamicBytes testBytes, dynamicBytes testBytes ]
