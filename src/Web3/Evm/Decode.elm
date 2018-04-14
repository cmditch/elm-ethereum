module Web3.Evm.Decode exposing (..)

import BigInt exposing (BigInt)
import Hex
import String.Extra as String
import Result.Extra as Result
import Json.Decode as Decode exposing (Decoder)
import Web3.Decode exposing (resultToDecoder)
import Web3.Utils exposing (add0x, remove0x, toAddress)
import Web3.Types exposing (Address, IPFSHash)


-- import Base58


type alias EvmDecoder a =
    Tape -> Result String ( Tape, a )


{-| Tape == (Original Tape, Altered Tape)

    Altered Tape:  Tape that is being read and eaten up in 32 byte / 64 character chunks

    Oringal Tape:   Untouched copy of the initial input string, i.e., the full hex return from a JSON RPC Call.
                    This remains untouched during the entire decoding process,
                    and is needed to help grab dynamic solidity values, such as 'bytes', 'address[]', or 'uint256[]'

-}
type alias Tape =
    ( String, String )


evmDecode : a -> EvmDecoder a
evmDecode r =
    \tape -> Ok ( tape, r )


runDecoder : EvmDecoder a -> String -> Result String a
runDecoder evmDecoder evmString =
    remove0x evmString
        |> (\a -> ( a, a ))
        |> evmDecoder
        |> Result.map Tuple.second


toElmDecoder : EvmDecoder a -> Decoder a
toElmDecoder =
    runDecoder >> resultToDecoder



-- Decoders


uint : EvmDecoder BigInt
uint =
    \( original, altered ) ->
        take64 altered
            |> add0x
            |> BigInt.fromString
            |> Result.fromMaybe "Error Decoding Uint into BigInt"
            |> Result.map (\bi -> ( ( original, drop64 altered ), bi ))


bool : EvmDecoder Bool
bool =
    let
        parseBool b =
            case String.left 63 b |> String.all ((==) '0') of
                True ->
                    case String.right 1 b of
                        "0" ->
                            Ok False

                        "1" ->
                            Ok True

                        _ ->
                            Err ("Boolean decode error." ++ b ++ " is not boolean.")

                False ->
                    Err ("Boolean decode error." ++ b ++ " is not boolean.")
    in
        \( original, altered ) ->
            take64 altered
                |> parseBool
                |> Result.map (\bi -> ( ( original, drop64 altered ), bi ))


address : EvmDecoder Address
address =
    \( original, altered ) ->
        take64 altered
            |> toAddress
            |> Result.map (\address -> ( ( original, drop64 altered ), address ))


{-| Decode Dynamically Sized Arrays
(dArray address) == address[]
-}
dArray : EvmDecoder a -> EvmDecoder (List a)
dArray decoder =
    \( original, altered ) ->
        take64 altered
            |> buildDynArray original
            |> Result.map (List.map (unpackDecoder decoder))
            |> Result.andThen Result.combine
            |> Result.map (\list -> ( ( original, drop64 altered ), list ))


{-| Decode Statically Sized Arrays
(sArray 10 uint) == uint256[10]
-}
sArray : Int -> EvmDecoder a -> EvmDecoder (List a)
sArray arrSize decoder =
    \( original, altered ) ->
        String.left (arrSize * 64) altered
            |> String.break 64
            |> List.map (unpackDecoder decoder)
            |> Result.combine
            |> Result.map (\list -> ( ( original, String.dropLeft (arrSize * 64) altered ), list ))



-- {-| Decodes bytes32 into IPFS Hash (assuming use of 32 byte sha256)
-- Not IPFS future proof. See <https://ethereum.stackexchange.com/questions/17094/how-to-store-ipfs-hash-using-bytes>
-- -}
-- ipfsHash : EvmDecoder IPFSHash
-- ipfsHash =
--     \( original, altered ) ->
--         take64 altered
--             |> (++) "0x1220"
--             |> BigInt.fromString
--             |> Maybe.map Base58.encode
--             |> Result.fromMaybe "Error Encoding IPFS Hash from BigInt"
--             |> Result.andThen makeIPFSHash
--             |> Result.map (\ipfsHash -> ( ( original, drop64 altered ), ipfsHash ))
-- {-| Prepares IPFS Hash to store as soldity bytes32
-- -}
-- ipfsToBytes32 : IPFSHash -> String
-- ipfsToBytes32 (IPFSHash str) =
--     Base58.decode str
--         |> Result.map (BigInt.toHexString >> String.dropLeft 4)
--         |> Result.withDefault "this should never happen, document what you did to get this outcome"


{-| Useful for decoding data withing events/logs.
-}
dropBytes : Int -> EvmDecoder a -> EvmDecoder a
dropBytes location decoder =
    \( original, altered ) ->
        String.dropLeft (location * 64) altered
            |> (,) original
            |> decoder


{-| Useful for decoding data withing events/logs.
-}
topic : Int -> EvmDecoder a -> Decoder a
topic index evmDecoder =
    toElmDecoder evmDecoder
        |> Decode.index index
        |> Decode.field "topics"


{-| Useful for decoding data withing events/logs.
-}
data : Int -> EvmDecoder a -> Decoder a
data index evmDecoder =
    toElmDecoder (dropBytes index evmDecoder)
        |> Decode.field "data"


{-| Chain and Map Decoders

andMap is the same as `apply` or `<*>` in Haskell, except initial arguments are flipped to help with elm pipeline syntax.

-}
andMap : EvmDecoder a -> EvmDecoder (a -> b) -> EvmDecoder b
andMap dVal dFunc =
    map2 (\f v -> f v) dFunc dVal


map2 : (a -> b -> c) -> EvmDecoder a -> EvmDecoder b -> EvmDecoder c
map2 f decA decB =
    \tape0 ->
        decA tape0
            |> Result.andThen
                (\( tape1, vA ) ->
                    decB tape1
                        |> Result.map (Tuple.mapSecond (f vA))
                )


{-| Takes the index pointer to the beginning of the array data (the first piece being the array length)
and the full return data, and slices out the

Example - Here is a returns(address[],uint256)

        0000000000000000000000000000000000000000000000000000000000000040 -- Start index of address[] (starts at byte 64, or the 128th character)
        0000000000000000000000000000000000000000000000000000000000000123 -- Some Uint256
        0000000000000000000000000000000000000000000000000000000000000003 -- Length of address[]
        000000000000000000000000ED9878336d5187949E4ca33359D2C47c846c9Dd3 -- First Address
        0000000000000000000000006A987e3C0cd7Ed478Ce18C4cE00a0B313299365B -- Second Address
        000000000000000000000000aD9178336d523494914ca37359D2456ef123466c -- Third Address

    buildDynArray fullReturnData startIndex
        > Ok ["000000000000000000000000ED9878336d5187949E4ca33359D2C47c846c9Dd3", secondAddress, thirdAddress]

-}
buildDynArray : String -> String -> Result String (List String)
buildDynArray fullTape startIndex =
    let
        toIntIndex =
            Hex.fromString >> Result.map ((*) 2)

        sliceData dataIndex arrLength =
            String.slice dataIndex (dataIndex + (arrLength * 64)) fullTape
    in
        toIntIndex startIndex
            |> Result.andThen
                (\index ->
                    String.slice index (index + 64) fullTape
                        |> Hex.fromString
                        |> Result.map (sliceData <| index + 64)
                )
            |> Result.map (String.break 64)


{-| Applies decoder to value without bothering with Tape State
Useful for mapping over lists built from dynamic types
-}
unpackDecoder : EvmDecoder a -> String -> Result String a
unpackDecoder decoder val =
    decoder ( "", val )
        |> Result.map Tuple.second



-- Utils


take64 : String -> String
take64 =
    String.left 64


drop64 : String -> String
drop64 =
    String.dropLeft 64
