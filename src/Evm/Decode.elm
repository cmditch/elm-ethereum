module Evm.Decode
    exposing
        ( EvmDecoder
        , uint
        , int
        , bool
        , address
        , string
        , staticBytes
        , dynamicBytes
        , staticArray
        , dynamicArray
        , ipfsHash
        , evmDecode
        , andMap
        , toElmDecoder
        , toElmDecoderWithDebug
        , fromString
        , topic
        , data
        )

{-| Decode RPC Responses

)


# Primitives

@docs EvmDecoder, uint, int, bool, address, string


# Bytes

@docs staticBytes, dynamicBytes


# Arrays

@docs staticArray, dynamicArray


# Special

@docs ipfsHash


# Run Decoders

@docs evmDecode, andMap, toElmDecoder, toElmDecoderWithDebug, fromString


# Events/Logs

@docs topic, data

-}

--
-- Take inspiration from Json.Decode.Pipeline
-- and Json.Decode
--

import Base58
import BigInt exposing (BigInt)
import Internal.Decode exposing (resultToDecoder)
import Eth.Types exposing (IPFSHash, Address)
import Eth.Utils as U exposing (toAddress)
import Evm.Int as EvmInt
import Hex
import Internal.Utils exposing (..)
import String.UTF8 as UTF8
import String.Extra as StringExtra
import Result.Extra as ResultExtra
import Json.Decode as Decode exposing (Decoder)


{-| -}
type EvmDecoder a
    = EvmDecoder (Tape -> Result String ( Tape, a ))


{-|

    Tape == Tape Original Altered

    Altered : Tape that is being read and eaten up in 32 byte / 64 character chunks, and passed down to the next decoder

    Original : Untouched copy of the initial input string, i.e., the full hex return from a JSON RPC Call.
               This remains untouched during the entire decoding process,
               and is needed to help grab dynamic solidity values, such as 'bytes', 'address[]', or 'uint256[]'
-}
type Tape
    = Tape String String


{-| Similar to Json.Decode.Pipeline.decode
also a synonym for Json.Decode.succeed
-}
evmDecode : a -> EvmDecoder a
evmDecode val =
    EvmDecoder (\tape -> Ok ( tape, val ))


{-| -}
andMap : EvmDecoder a -> EvmDecoder (a -> b) -> EvmDecoder b
andMap dVal dFunc =
    map2 (\f v -> f v) dFunc dVal


{-| -}
fromString : EvmDecoder a -> String -> Result String a
fromString =
    decodeStringWithDebug Nothing


{-| -}
toElmDecoder : EvmDecoder a -> Decoder a
toElmDecoder =
    decodeStringWithDebug Nothing >> resultToDecoder


{-| -}
toElmDecoderWithDebug : String -> EvmDecoder a -> Decoder a
toElmDecoderWithDebug functionName =
    decodeStringWithDebug (Just functionName) >> resultToDecoder



-- Internal Runners


{-| -}
decodeStringWithDebug : Maybe String -> EvmDecoder a -> String -> Result String a
decodeStringWithDebug debug (EvmDecoder evmDecoder) evmString =
    let
        _ =
            case debug of
                Just function ->
                    Debug.log ("Debug Contract Call Response " ++ function) evmString

                Nothing ->
                    evmString
    in
        remove0x evmString
            |> (\a -> Tape a a)
            |> evmDecoder
            |> Result.map Tuple.second


{-| -}
map : (a -> b) -> EvmDecoder a -> EvmDecoder b
map f (EvmDecoder decA) =
    EvmDecoder <|
        \tape0 ->
            decA tape0
                |> Result.map (Tuple.mapSecond f)


{-| -}
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



-- Primitives


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
int : EvmDecoder BigInt
int =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> EvmInt.fromString
                |> Result.fromMaybe "Error Decoding Int into BigInt"
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
string : EvmDecoder String
string =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> buildBytes original
                |> Result.map (StringExtra.break 2)
                |> Result.andThen (List.map Hex.fromString >> ResultExtra.combine)
                |> Result.andThen UTF8.toString
                |> Result.map (newTape original altered)



-- Bytes
-- TODO - Change to Hex?


{-| -}
staticBytes : Int -> EvmDecoder String
staticBytes bytesLen =
    EvmDecoder <|
        \(Tape original altered) ->
            String.left (bytesLen * 2) altered
                |> add0x
                |> Ok
                |> Result.map (newTape original altered)


{-| -}
dynamicBytes : EvmDecoder String
dynamicBytes =
    EvmDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> buildBytes original
                |> Result.map add0x
                |> Result.map (newTape original altered)



-- Arrays


{-| Decode Statically Sized Arrays

    staticArray 10 uint == uint256[10]

-}
staticArray : Int -> EvmDecoder a -> EvmDecoder (List a)
staticArray len dec =
    EvmDecoder <|
        arrayHelp [] len dec


{-| Decode Dynamically Sized Arrays

    dynamicArray address == address[]

-}



{- Dev Notes for Dynamic array decoder

   Example array-of-vectors `uint[2][]` returned from the ABI
   We'll use a multi-return value data type of `myFunc(uint[2][],uint,bool)`
   And use 4 byte words, instead of 32 byte words.
   -----------------------------------
   0000000c  -  arrayDataPointer - says array data starts after 12 bytes (0xc == 12 == 24 chars)
   00000042  -  uint of 0x42
   00000001  -  bool of true
   00000003  -  start of dynamic array (24 bytes in). This says "I am three in length, of whatever data type I'm comrpised of". In this case `uint[2]`
   00000001  -  first element of first uint[2]
   00000002  -  last element of first uint[2]
   00000003  -  first element of second uint[2]
   00000004  -  last element of second uint[2]
   00000005  -  first element of last uint[2]
   00000006  -  last element of last uint[2]

   This will decode to `{ dynArrayOfUintVector = [[1,2], [3,4], [5,6]], singleUint = 66, singleBool = True }`
-}


dynamicArray : EvmDecoder a -> EvmDecoder (List a)
dynamicArray valDecoder =
    EvmDecoder <|
        \(Tape original altered) ->
            let
                getPointerToArrayData : Result String Int
                getPointerToArrayData =
                    take64 altered
                        |> Hex.fromString
                        |> Result.map ((*) 2)

                getArrayData : Int -> Result String ( Int, String )
                getArrayData lengthIndex =
                    String.slice lengthIndex (lengthIndex + 64) original
                        |> Hex.fromString
                        |> Result.map (\arrayLength -> ( arrayLength, String.dropLeft (lengthIndex + 64) original ))
            in
                getPointerToArrayData
                    |> Result.andThen getArrayData
                    |> Result.andThen
                        (\( arrayLength, rawArrayData ) ->
                            (Tape original rawArrayData)
                                |> arrayHelp [] arrayLength valDecoder
                                |> Result.map
                                    (\( Tape _ _, arrayData ) ->
                                        ( Tape original (drop64 altered), arrayData )
                                    )
                        )


{-|

    Accumulates a list of decoded values.
    The `altered` tape will be eaten up as the value decoder works away one value at a time.
    The list of decoded values, along with the newly altered tape is returned

    The old versions of array decoding assumed all values inside the array were 32 bytes chunks.
    And would break the string into 32 byte chunks and map a decoder over them.
    This new fold style approach, vs the previous map style approach,
    helps us deal with array elements of arbitrary lengths.
-}
arrayHelp : List a -> Int -> EvmDecoder a -> Tape -> Result String ( Tape, List a )
arrayHelp accum len (EvmDecoder decoder) tape =
    case len of
        0 ->
            Ok ( tape, List.reverse accum )

        n ->
            decoder tape
                |> Result.andThen
                    (\( tape, val ) ->
                        arrayHelp (val :: accum) (n - 1) (EvmDecoder decoder) tape
                    )



-- Special


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
                |> Result.andThen U.toIPFSHash
                |> Result.map (newTape original altered)



-- Events/Logs


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



-- Internal


{-| -}
newTape : String -> String -> a -> ( Tape, a )
newTape original altered val =
    ( Tape original (drop64 altered), val )


{-| Takes the index pointer to the beginning of a given string/bytes value (the first 32 bytes being the data length)

Example -

       0000000000000000000000000000000000000000000000000000000000000020 -- Start index of data is 0x20 or byte number 32 / char number 64
       0000000000000000000000000000000000000000000000000000000000000044 -- First 32 bytes describes the length of the actual data, in this case 68 bytes or 136 chars
       446f657320746869732077686f6c652073656e74656e6365206d616b6520697420696e20746865206d697820686572653f2021402324255e262a2829203a2920f09f988600000000000000000000000000000000000000000000000000000000  -- Data

       136 chars of data, 192 chars total

-}
buildBytes : String -> String -> Result String String
buildBytes fullTape lengthIndex =
    -- TODO Test this works with dynamic lists
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


{-| Useful for decoding data withing events/logs.
-}
dropBytes : Int -> EvmDecoder a -> EvmDecoder a
dropBytes location (EvmDecoder decoder) =
    EvmDecoder <|
        \(Tape original altered) ->
            String.dropLeft (location * 64) altered
                |> Tape original
                |> decoder
