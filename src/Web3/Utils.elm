module Web3.Utils exposing (..)

import BigInt exposing (BigInt)
import Bool.Extra exposing (all)
import Char
import Hex
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Keccak exposing (ethereum_keccak_256)
import Regex exposing (Regex)
import Result.Extra as Result
import String.Extra as String
import Web3.Internal.Types as Internal
import Web3.Internal.Utils as Internal exposing (quote, toByteLength)
import Web3.Eth.Types exposing (..)
import Web3.Types exposing (Hex)


toAddress : String -> Result String Address
toAddress str =
    let
        noZeroX =
            remove0x str

        isLower =
            isLowerCaseAddress noZeroX

        isUpper =
            isUpperCaseAddress noZeroX
    in
        if String.length noZeroX < 40 then
            Err <| "Given address " ++ quote str ++ " is too short"
        else if String.length noZeroX > 40 then
            Err <| "Given address " ++ quote str ++ " is too long"
        else if not (isAddress noZeroX) then
            Err <| "Given address " ++ quote str ++ " contains invalid hex characters."
        else if isUpper || isLower then
            toChecksumAddress str
        else if (isChecksumAddress noZeroX) then
            Ok <| Internal.Address noZeroX
        else
            Err <| "Given address " ++ quote str ++ " failed the EIP-55 checksum test."


toChecksumAddress : String -> Result String Address
toChecksumAddress str =
    let
        compareCharToHash addrChar hashInt =
            if hashInt >= 8 then
                Char.toUpper addrChar
            else
                addrChar

        checksumIt str_ =
            uncurry (List.map2 compareCharToHash) (checksumHelper str_)
                |> String.fromList
                |> Internal.Address
    in
        if isAddress str then
            Ok <| checksumIt str
        else
            Err <| "Given address " ++ quote str ++ " is not a valid Ethereum address."


isChecksumAddress : String -> Bool
isChecksumAddress str =
    let
        checksumTestChar addrChar hashInt =
            if hashInt >= 8 && Char.isLower addrChar || hashInt < 8 && Char.isUpper addrChar then
                False
            else
                True

        checksumCorrect =
            uncurry (List.map2 checksumTestChar) (checksumHelper str)
    in
        if isAddress str then
            all checksumCorrect
        else
            False


{-| Takes first 20 bytes of keccak'd address, and converts each hex char to an int
Packs this list into a tuple with the split up address chars so a comparison can be made between the two.
-}
checksumHelper : String -> ( List Char, List Int )
checksumHelper address =
    let
        addressChars =
            String.toList (remove0x address)
    in
        addressChars
            |> List.map (Char.toLower >> Char.toCode)
            |> ethereum_keccak_256
            |> List.take 20
            |> List.map (Hex.toString >> toByteLength)
            |> String.join ""
            |> String.split ""
            |> List.map Hex.fromString
            |> Result.combine
            |> Result.withDefault []
            |> (,) addressChars


toHex : String -> Result String Hex
toHex str =
    if isHex str then
        Ok <| Internal.Hex (remove0x str)
    else
        Err <| "Given hex " ++ quote str ++ " is not valid."


toTxHash : String -> Result String TxHash
toTxHash str =
    if isSha256 str then
        Ok <| Internal.TxHash (remove0x str)
    else
        Err <| "Given txHash " ++ quote str ++ " is not valid."


toBlockHash : String -> Result String BlockHash
toBlockHash str =
    if isSha256 str then
        Ok <| Internal.BlockHash (remove0x str)
    else
        Err <| "Given blockHash " ++ quote str ++ " is not valid."



-- toString


hexToString : Hex -> String
hexToString (Internal.Hex hex) =
    add0x hex


addressToString : Address -> String
addressToString (Internal.Address address) =
    add0x address


txHashToString : TxHash -> String
txHashToString (Internal.TxHash txHash) =
    add0x txHash


blockHashToString : BlockHash -> String
blockHashToString (Internal.BlockHash blockHash) =
    add0x blockHash



-- Regex


isAddress : String -> Bool
isAddress =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9A-Fa-f]{40}$")


isLowerCaseAddress : String -> Bool
isLowerCaseAddress =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9a-f]{40}$")


isUpperCaseAddress : String -> Bool
isUpperCaseAddress =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9A-F]{40}$")


isSha256 : String -> Bool
isSha256 =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9a-fA-F]{64}$")


isHex : String -> Bool
isHex =
    Regex.contains (Regex.regex "^((0[Xx]){1})?[0-9a-fA-F]+$")



-- String Helpers


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


hexToAscii : String -> Result String String
hexToAscii str =
    case String.length str % 2 == 0 of
        True ->
            remove0x str
                |> String.break 2
                |> List.map Hex.fromString
                |> Result.combine
                |> Result.map (String.fromList << List.map Char.fromCode)

        False ->
            Err (quote str ++ " is not ascii hex. Uneven length. Byte pairs required.")


functionSig : String -> String
functionSig fSig =
    String.toList fSig
        |> List.map Char.toCode
        |> ethereum_keccak_256
        |> List.take 4
        |> List.map (Hex.toString >> toByteLength)
        |> String.join ""
        |> (++) "0x"



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
    String.toList str
        |> List.map Char.toCode
        |> ethereum_keccak_256
        |> List.map (Hex.toString >> toByteLength)
        |> String.join ""
        |> (++) "0x"



-- VALUE UTILS


gwei : Int -> BigInt
gwei =
    BigInt.fromInt >> BigInt.mul (BigInt.fromInt 1000000000)


eth : Int -> BigInt
eth =
    let
        oneEth =
            BigInt.mul (BigInt.fromInt 100) (BigInt.fromInt 10000000000000000)
    in
        BigInt.fromInt >> (BigInt.mul oneEth)



-- APP UTILS


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
