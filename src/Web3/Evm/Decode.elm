module Web3.Evm.Decode
    exposing
        ( EvmDecoder
        , evmDecode
        , runDecoder
        , toElmDecoder
        , toElmDecoderWithDebug
        , uint
        , bool
        , address
        , dBytes
        , sBytes
        , string
        , dArray
        , sArray
        , ipfsHash
        , topic
        , data
        , andMap
        , map2
        )

{-| Decode RPC Responses

@docs EvmDecoder, evmDecode, runDecoder, toElmDecoder, toElmDecoderWithDebug
@docs uint, bool, address, dBytes, sBytes, string, dArray, sArray, ipfsHash
@docs topic, data, andMap, map2

-}

import Base58
import BigInt exposing (BigInt)
import Hex
import String.UTF8 as UTF8
import String.Extra as String
import Result.Extra as Result
import Json.Decode as Decode exposing (Decoder)
import Web3.Decode exposing (resultToDecoder)
import Web3.Eth.Types exposing (Address)
import Web3.Types exposing (IPFSHash)
import Web3.Evm.Utils exposing (take64, drop64)
import Web3.Utils exposing (add0x, remove0x, toAddress, makeIPFSHash)


{-| -}
type EvmDecoder a
    = EvmDecoder (Tape -> Result String ( Tape, a ))



{- Tape == Tape Original Altered

   Altered  :  Tape that is being read and eaten up in 32 byte / 64 character chunks, and passed down to the next decoder

   Oringal  :  Untouched copy of the initial input string, i.e., the full hex return from a JSON RPC Call.
               This remains untouched during the entire decoding process,
               and is needed to help grab dynamic solidity values, such as 'bytes', 'address[]', or 'uint256[]'

-}


type Tape
    = Tape String String


{-| -}
evmDecode : a -> EvmDecoder a
evmDecode val =
    EvmDecoder (\tape -> Ok ( tape, val ))


{-| -}
runDecoder : Maybe String -> EvmDecoder a -> String -> Result String a
runDecoder debug (EvmDecoder evmDecoder) evmString =
    let
        str =
            case debug of
                Just function ->
                    Debug.log ("Debug Contract Call Response " ++ function) evmString

                Nothing ->
                    evmString
    in
        remove0x str
            |> (\a -> Tape a a)
            |> evmDecoder
            |> Result.map Tuple.second


{-| -}
toElmDecoder : EvmDecoder a -> Decoder a
toElmDecoder =
    runDecoder Nothing >> resultToDecoder


{-| -}
toElmDecoderWithDebug : String -> EvmDecoder a -> Decoder a
toElmDecoderWithDebug functionName =
    runDecoder (Just functionName) >> resultToDecoder



-- Decoders


{-| -}
uint : EvmDecoder BigInt
uint =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> add0x
                |> BigInt.fromString
                |> Result.fromMaybe "Error Decoding Uint into BigInt"
                |> Result.map (newTape original altered)


{-| -}
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
        EvmDecoder <|
            \(Tape original altered) ->
                take64 altered
                    |> parseBool
                    |> Result.map (newTape original altered)


{-| -}
address : EvmDecoder Address
address =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> toAddress
                |> Result.map (newTape original altered)


{-| -}
dBytes : EvmDecoder String
dBytes =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> buildBytes original
                |> Result.map add0x
                |> Result.map (newTape original altered)


{-| -}
sBytes : Int -> EvmDecoder String
sBytes bytesLen =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> add0x
                |> Ok
                |> Result.map (newTape original altered)


{-| -}
string : EvmDecoder String
string =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> buildBytes original
                |> Result.map (String.break 2)
                |> Result.andThen (List.map Hex.fromString >> Result.combine)
                |> Result.andThen UTF8.toString
                |> Result.map (newTape original altered)


{-| Decode Dynamically Sized Arrays
(dArray address) == address[]
-}
dArray : EvmDecoder a -> EvmDecoder (List a)
dArray decoder =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> buildDynArray original
                |> Result.map (List.map (unpackDecoder decoder))
                |> Result.andThen Result.combine
                |> Result.map (newTape original altered)


{-| Decode Statically Sized Arrays
(sArray 10 uint) == uint256[10]
-}
sArray : Int -> EvmDecoder a -> EvmDecoder (List a)
sArray arrSize decoder =
    EvmDecoder <|
        \(Tape original altered) ->
            String.left (arrSize * 64) altered
                |> String.break 64
                |> List.map (unpackDecoder decoder)
                |> Result.combine
                |> Result.map (\list -> ( Tape original (String.dropLeft (arrSize * 64) altered), list ))


{-| Decodes bytes32 into IPFS Hash (assuming use of 32 byte sha256)
Not IPFS future proof. See <https://ethereum.stackexchange.com/questions/17094/how-to-store-ipfs-hash-using-bytes>
-}
ipfsHash : EvmDecoder IPFSHash
ipfsHash =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> (++) "0x1220"
                |> BigInt.fromString
                |> Maybe.map Base58.encode
                |> Result.fromMaybe "Error Encoding IPFS Hash from BigInt"
                |> Result.andThen makeIPFSHash
                |> Result.map (newTape original altered)


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



-- Useful for decoding data withing events/logs.


dropBytes : Int -> EvmDecoder a -> EvmDecoder a
dropBytes location (EvmDecoder decoder) =
    EvmDecoder <|
        \(Tape original altered) ->
            String.dropLeft (location * 64) altered
                |> Tape original
                |> decoder


{-| Chain and Map Decoders

andMap is the same as `apply` or `<*>` in Haskell, except initial arguments are flipped to help with elm pipeline syntax.

-}
map2 : (a -> b -> c) -> EvmDecoder a -> EvmDecoder b -> EvmDecoder c
map2 f (EvmDecoder decA) (EvmDecoder decB) =
    EvmDecoder <|
        \tape0 ->
            decA tape0
                |> Result.andThen
                    (\( tape1, vA ) ->
                        decB tape1
                            |> Result.map (Tuple.mapSecond (f vA))
                    )


{-| -}
andMap : EvmDecoder a -> EvmDecoder (a -> b) -> EvmDecoder b
andMap dVal dFunc =
    map2 (\f v -> f v) dFunc dVal


newTape : String -> String -> a -> ( Tape, a )
newTape original altered val =
    ( Tape original (drop64 altered), val )



{- Takes the index pointer to the beginning of a given string/bytes value (the first 32 bytes being the data length)

   Example -

       0000000000000000000000000000000000000000000000000000000000000020 -- Start index of data is 0x20 or byte number 32 / char number 64
       0000000000000000000000000000000000000000000000000000000000000044 -- First 32 bytes describes the length of the actual data, in this case 68 bytes or 136 chars
       446f657320746869732077686f6c652073656e74656e6365206d616b6520697420696e20746865206d697820686572653f2021402324255e262a2829203a2920f09f988600000000000000000000000000000000000000000000000000000000  -- Data

       136 chars of data, 192 chars total

-}


buildBytes : String -> String -> Result String String
buildBytes fullTape lengthIndex =
    let
        hexToLength =
            Hex.fromString >> Result.map ((*) 2)

        sliceData dataIndex strLength =
            String.slice dataIndex (dataIndex + (strLength * 2)) fullTape
    in
        hexToLength lengthIndex
            |> Result.andThen
                (\index ->
                    String.slice index (index + 64) fullTape
                        |> Hex.fromString
                        |> Result.map (\dataLength -> sliceData (index + 64) dataLength)
                )



{- Takes the index pointer to the beginning of the array data (the first piece being the array length)
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
buildDynArray fullTape lengthIndex =
    let
        hexToLength =
            Hex.fromString >> Result.map ((*) 2)

        sliceData dataIndex arrLength =
            String.slice dataIndex (dataIndex + (arrLength * 64)) fullTape
    in
        hexToLength lengthIndex
            |> Result.andThen
                (\index ->
                    String.slice index (index + 64) fullTape
                        |> Hex.fromString
                        |> Result.map (\dataLength -> sliceData (index + 64) dataLength)
                )
            |> Result.map (String.break 64)



{- Applies decoder to value without bothering with Tape State
   Useful for mapping over lists built from dynamic types
-}


unpackDecoder : EvmDecoder a -> String -> Result String a
unpackDecoder (EvmDecoder decoder) val =
    decoder (Tape "" val)
        |> Result.map Tuple.second
