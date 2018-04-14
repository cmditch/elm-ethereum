module Web3.Utils exposing (..)

-- Library

import Ascii
import Base58
import BigInt exposing (BigInt)
import Hex
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Keccak exposing (ethereum_keccak_256)
import Regex
import Result.Extra as Result
import String.Extra as String


-- Internal

import Web3.Internal.Utils as Internal
import Web3.Types exposing (..)


-- Utils


toAddress : String -> Result String Address
toAddress =
    Internal.toAddress


addressToString : Address -> String
addressToString =
    Internal.addressToString



-- Old


add0x : String -> String
add0x str =
    if String.startsWith "0x" str then
        str
    else
        "0x" ++ str


remove0x : String -> String
remove0x str =
    if String.startsWith "0x" str then
        String.dropLeft 2 str
    else
        str


leftPad : String -> String
leftPad data =
    String.padLeft 64 '0' data


listOfMaybesToVal : List ( String, Maybe Value ) -> Value
listOfMaybesToVal keyValueList =
    keyValueList
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault Encode.null v ))
        |> Encode.object


hexToAscii : String -> Result String String
hexToAscii str =
    case String.length str % 2 == 0 of
        True ->
            remove0x str
                |> String.break 2
                |> List.map Hex.fromString
                |> Result.combine
                |> Result.map Ascii.toString

        False ->
            Err ("Data is not ascii hex. Uneven length. Byte pairs required.")


{-| Help with decoding past a result straight into a Msg
-}
valToMsg : (a -> msg) -> (String -> msg) -> Decoder a -> (Value -> msg)
valToMsg successMsg failureMsg decoder =
    let
        resultToMessage result =
            case result of
                Ok val ->
                    successMsg val

                Err error ->
                    failureMsg error
    in
        resultToMessage << Decode.decodeValue decoder



-- TODO This needs to be tightened up a lot. Checksum conversion, etc. Very naive implementation.


functionSig : String -> String
functionSig fSig =
    let
        toByteLength s =
            if String.length s == 1 then
                String.append "0" s
            else
                s
    in
        Ascii.fromString fSig
            |> ethereum_keccak_256
            |> List.take 4
            |> List.map (Hex.toString >> toByteLength)
            |> String.join ""
            |> (++) "0x"


zeroAddress : Address
zeroAddress =
    Internal.zeroAddress



-- ipfsHashToString : IPFSHash -> String
-- ipfsHashToString (IPFSHash str) =
--     str
-- makeIPFSHash : String -> Result String IPFSHash
-- makeIPFSHash str =
--     if String.length str /= 46 then
--         Err <| str ++ " is an invalid IPFS Hash. Must be 46 chars long."
--     else if String.left 2 str /= "Qm" then
--         Err <| str ++ " is an invalid IPFS Hash. Must begin with \"Qm\"."
--     else
--         Base58.decode str
--             |> Result.andThen (\_ -> Ok <| IPFSHash str)


keccak256 : String -> String
keccak256 str =
    let
        toByteLength s =
            if String.length s == 1 then
                String.append "0" s
            else
                s
    in
        Ascii.fromString str
            |> ethereum_keccak_256
            |> List.map (Hex.toString >> toByteLength)
            |> String.join ""
            |> (++) "0x"


getNetwork : Int -> NetworkId
getNetwork networkId =
    case networkId of
        1 ->
            Mainnet

        2 ->
            Expanse

        3 ->
            Ropsten

        4 ->
            Rinkeby

        30 ->
            RskMain

        31 ->
            RskTest

        42 ->
            Kovan

        41 ->
            ETCMain

        62 ->
            ETCTest

        _ ->
            Private networkId


getNetworkName : NetworkId -> String
getNetworkName networkId =
    case networkId of
        Mainnet ->
            "Mainnet"

        Expanse ->
            "Expanse"

        Ropsten ->
            "Ropsten"

        Rinkeby ->
            "Rinkeby"

        RskMain ->
            "Rootstock"

        RskTest ->
            "Rootstock Test"

        Kovan ->
            "Kovan"

        ETCMain ->
            "ETC Mainnet"

        ETCTest ->
            "ETC Testnet"

        Private networkId ->
            "Private Chain"



-- VALUE UTILS


gwei : Int -> BigInt
gwei =
    BigInt.fromInt >> BigInt.mul (BigInt.fromInt 1000000000)
