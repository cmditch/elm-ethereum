module Web3.Internal.Utils
    exposing
        ( toAddress
        , addressToString
        , toHex
        , hexToString
        , isChecksumAddress
        )

import Bool.Extra exposing (all)
import Char
import Keccak exposing (ethereum_keccak_256)
import Regex exposing (Regex)
import Result.Extra as Result
import Web3.Internal.Types exposing (Address(..), Hex(..), TxHash(..))
import Hex


-- Address


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
        if String.length noZeroX /= 40 then
            Err <| "Given address " ++ quote str ++ " is not 20 bytes long."
        else if not (isAddress noZeroX) then
            Err <| "Given address " ++ quote str ++ " contains invalid hex characters."
        else if isUpper || isLower then
            toChecksumAddress str
        else if (isChecksumAddress noZeroX) then
            Ok <| Address noZeroX
        else
            Err <| "Given address " ++ quote str ++ " failed the EIP-55 checksum test."


addressToString : Address -> String
addressToString (Address address) =
    address


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
                |> Address
    in
        if isAddress (remove0x str) then
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
        if isAddress (remove0x str) then
            all checksumCorrect
        else
            False


{-| Takes first 20 bytes of keccak'd address, and converts each hex char to an int
Packs this list into a tuple with the split up address chars so a comparison can be made between the two.
-}
checksumHelper : String -> ( List Char, List Int )
checksumHelper address =
    let
        toByteLength s =
            if String.length s == 1 then
                String.append "0" s
            else
                s

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



-- Hex


toHex : String -> Result String Hex
toHex str =
    if isHex (remove0x str) then
        Ok <| Hex str
    else
        Err <| "Given hex " ++ quote str ++ " is not a valid."


hexToString : Hex -> String
hexToString (Hex hex) =
    hex



-- Regex


isAddress : String -> Bool
isAddress =
    Regex.contains (Regex.regex "^[0-9A-Fa-f]{40}$")


isLowerCaseAddress : String -> Bool
isLowerCaseAddress =
    Regex.contains (Regex.regex "^[0-9a-f]{40}$")


isUpperCaseAddress : String -> Bool
isUpperCaseAddress =
    Regex.contains (Regex.regex "^[0-9A-F]{40}$")


isHex : String -> Bool
isHex =
    Regex.contains (Regex.regex "^[0-9a-fA-F]+$")



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


quote : String -> String
quote str =
    "\"" ++ str ++ "\""
