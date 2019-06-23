module Eth.Abi.Decode exposing
    ( AbiDecoder, uint, int, bool, address, string
    , staticBytes, dynamicBytes
    , staticArray, dynamicArray
    , abiDecode, andMap, toElmDecoder, fromString
    , topic, data
    )

{-| Decode RPC Responses

)


# Primitives

@docs AbiDecoder, uint, int, bool, address, string


# Bytes

@docs staticBytes, dynamicBytes


# Arrays

@docs staticArray, dynamicArray


# Run Decoders

@docs abiDecode, andMap, toElmDecoder, fromString


# Events/Logs

@docs topic, data

-}

import BigInt exposing (BigInt)
import Eth.Abi.Int as AbiInt
import Eth.Decode
import Eth.Types exposing (Address)
import Eth.Utils exposing (add0x, drop64, remove0x, take64)
import Hex
import Internal.Types exposing (Hex(..))
import Json.Decode as Decode exposing (Decoder)
import Result.Extra as ResultExtra
import String.Extra as StringExtra
import String.UTF8 as UTF8


{-|

    type Tape = Tape Original Altered

    Original : Untouched copy of the initial return value of the JSON RPC call.
                This remains untouched during the entire decoding process,
                and is needed to help grab dynamic values.
                E.g. 'bytes', 'string', `tuple` (structs), 'address[]', or 'uint256[][]'

    Altered : JSON RPC call return value that is being read and eaten up word by word,
              or 32 byte / 64 character chunks, and passed down to the next decoder.

-}
type Tape
    = Tape String String


{-| -}
type AbiDecoder a
    = AbiDecoder (Tape -> Result String ( Tape, a ))


{-| Similar to Json.Decode.succeed, or `pure` in Haskell
-}
abiDecode : a -> AbiDecoder a
abiDecode val =
    AbiDecoder (\tape -> Ok ( tape, val ))


{-| -}
andMap : AbiDecoder a -> AbiDecoder (a -> b) -> AbiDecoder b
andMap dVal dFunc =
    map2 (\f v -> f v) dFunc dVal


{-| -}
fromString : AbiDecoder a -> String -> Result String a
fromString (AbiDecoder abiDecoder) abiString =
    remove0x abiString
        |> (\a -> Tape a a)
        |> abiDecoder
        |> Result.map Tuple.second


{-| -}
toElmDecoder : AbiDecoder a -> Decoder a
toElmDecoder =
    fromString >> Eth.Decode.resultToDecoder


map : (a -> b) -> AbiDecoder a -> AbiDecoder b
map f (AbiDecoder decA) =
    AbiDecoder <|
        \tape0 ->
            decA tape0
                |> Result.map (Tuple.mapSecond f)


map2 : (a -> b -> c) -> AbiDecoder a -> AbiDecoder b -> AbiDecoder c
map2 f (AbiDecoder decA) (AbiDecoder decB) =
    AbiDecoder <|
        \tape0 ->
            decA tape0
                |> Result.andThen
                    (\( tape1, vA ) ->
                        decB tape1
                            |> Result.map (Tuple.mapSecond (f vA))
                    )



-- Primitives


{-| -}
uint : AbiDecoder BigInt
uint =
    AbiDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> add0x
                |> BigInt.fromHexString
                |> Result.fromMaybe "Error Decoding Uint into BigInt"
                |> Result.map (newTape original altered)


{-| -}
int : AbiDecoder BigInt
int =
    AbiDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> AbiInt.fromString
                |> Result.fromMaybe "Error Decoding Int into BigInt"
                |> Result.map (newTape original altered)


{-| -}
bool : AbiDecoder Bool
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
                            Err ("Boolean decode error. " ++ b ++ " is not 1 or 0.")

                False ->
                    Err ("Boolean decode error. " ++ b ++ " is not 1 or 0.")
    in
    AbiDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> parseBool
                |> Result.map (newTape original altered)


{-| -}
address : AbiDecoder Address
address =
    AbiDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> Eth.Utils.toAddress
                |> Result.map (newTape original altered)


{-| -}
string : AbiDecoder String
string =
    AbiDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> buildBytes original
                |> Result.map (StringExtra.break 2)
                |> Result.map (List.filter (String.isEmpty >> not))
                |> Result.andThen (List.map Hex.fromString >> ResultExtra.combine)
                |> Result.andThen UTF8.toString
                |> Result.map (newTape original altered)



-- Bytes
-- TODO - Change to Hex?


{-| -}
staticBytes : Int -> AbiDecoder Hex
staticBytes bytesLen =
    AbiDecoder <|
        \(Tape original altered) ->
            String.left (bytesLen * 2) altered
                |> Hex
                |> Ok
                |> Result.map (newTape original altered)


{-| -}
dynamicBytes : AbiDecoder Hex
dynamicBytes =
    AbiDecoder <|
        \(Tape original altered) ->
            take64 altered
                |> buildBytes original
                |> Result.map Hex
                |> Result.map (newTape original altered)



-- Arrays


{-| Decode Statically Sized Arrays

    staticArray 10 uint == uint256 [ 10 ]

-}
staticArray : Int -> AbiDecoder a -> AbiDecoder (List a)
staticArray len dec =
    AbiDecoder <|
        arrayHelp [] len dec


{-| Decode Dynamically Sized Arrays
-}



{- Dev Notes for Dynamic array decoder:

   Example array-of-vectors `uint[2][]` returned from the ABI
   We'll use a multi-return value data type of `myFunc() returns (uint256[2][], uint, bool)`
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


dynamicArray : AbiDecoder a -> AbiDecoder (List a)
dynamicArray valDecoder =
    AbiDecoder <|
        \((Tape original altered) as tape) ->
            let
                -- Result String ( Array Length, Array Data )
                getArrayData : Int -> Result String ( Int, String )
                getArrayData lengthIndex =
                    String.slice lengthIndex (lengthIndex + 64) original
                        |> Hex.fromString
                        |> Result.map (\arrayLength -> ( arrayLength, String.dropLeft (lengthIndex + 64) original ))
            in
            parsePointer tape
                |> Result.andThen getArrayData
                |> Result.andThen
                    (\( arrayLength, rawArrayData ) ->
                        Tape rawArrayData rawArrayData
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
    helps us deal with array elements of arbitrary lengths, and even arrays within arrays.

-}
arrayHelp : List a -> Int -> AbiDecoder a -> Tape -> Result String ( Tape, List a )
arrayHelp accum len (AbiDecoder decoder) tape =
    case len of
        0 ->
            Ok ( tape, List.reverse accum )

        n ->
            decoder tape
                |> Result.andThen
                    (\( tape_, val ) ->
                        arrayHelp (val :: accum) (n - 1) (AbiDecoder decoder) tape_
                    )


{-| DO NOT USE YET, IN PROGRESS.
odd Struct behavior in Solidity
-}
struct : AbiDecoder a -> AbiDecoder a
struct (AbiDecoder decoder) =
    AbiDecoder <|
        \((Tape original altered) as tape) ->
            parsePointer tape
                |> Result.map (\dataIndex -> String.dropLeft dataIndex original)
                |> Result.andThen (\rawStructData -> decoder (Tape rawStructData rawStructData))
                |> Result.map
                    (\( Tape _ _, structData ) ->
                        ( Tape original (drop64 altered), structData )
                    )


{-| Grabs the first word off the `altered` tape,
a uint pointing to some part of the unlatered tape, or `original`, where the relevant data exists.
Pointers are used for dynamic data types like arrays, strings, bytes, and structs.
-}
parsePointer : Tape -> Result String Int
parsePointer (Tape _ altered) =
    take64 altered
        |> Hex.fromString
        |> Result.map ((*) 2)



-- Special
-- Events/Logs
-- TODO Consider re-writing this to get it to play nicer with Logs instead of Events


{-| Useful for decoding data withing events/logs.
-}
topic : Int -> AbiDecoder a -> Decoder a
topic index abiDecoder =
    toElmDecoder abiDecoder
        |> Decode.index index
        |> Decode.field "topics"


{-| Useful for decoding data withing events/logs.

TODO - Will this work if dynamic types are in the log data?
dropBytes might mess with the length of grabbing dyn vals off the Original Tape

-}
data : Int -> AbiDecoder a -> Decoder a
data index abiDecoder =
    toElmDecoder (dropBytes index abiDecoder)
        |> Decode.field "data"



-- Internal


{-| Eat and accumulate. Travel down the tape one word at a time, and return the value from what was just eaten.
-}
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


{-| Useful for decoding data within events/logs.
-}
dropBytes : Int -> AbiDecoder a -> AbiDecoder a
dropBytes location (AbiDecoder decoder) =
    AbiDecoder <|
        \(Tape original altered) ->
            String.dropLeft (location * 64) altered
                |> Tape original
                |> decoder
