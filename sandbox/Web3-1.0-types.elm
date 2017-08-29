import Json.Encode
import Json.Decode
import Json.Decode.Pipeline

type alias Something =
    { address : String
    , blockNumber : Int
    , transactionHash : String
    , transactionIndex : Int
    , blockHash : String
    , logIndex : Int
    , removed : Bool
    , id : String
    , returnValues : SomethingReturnValues
    , event : String
    , signature : String
    , raw : SomethingRaw
    }

type alias SomethingReturnValues =
    { 0 : String
    , 1 : String
    , 2 : String
    , from : String
    , to : String
    , value : String
    }

type alias SomethingRaw =
    { data : String
    , topics : List String
    }

decodeSomething : Json.Decode.Decoder Something
decodeSomething =
    Json.Decode.Pipeline.decode Something
        |> Json.Decode.Pipeline.required "address" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "blockNumber" (Json.Decode.int)
        |> Json.Decode.Pipeline.required "transactionHash" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "transactionIndex" (Json.Decode.int)
        |> Json.Decode.Pipeline.required "blockHash" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "logIndex" (Json.Decode.int)
        |> Json.Decode.Pipeline.required "removed" (Json.Decode.bool)
        |> Json.Decode.Pipeline.required "id" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "returnValues" (decodeSomethingReturnValues)
        |> Json.Decode.Pipeline.required "event" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "signature" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "raw" (decodeSomethingRaw)

decodeSomethingReturnValues : Json.Decode.Decoder SomethingReturnValues
decodeSomethingReturnValues =
    Json.Decode.Pipeline.decode SomethingReturnValues
        |> Json.Decode.Pipeline.required "0" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "1" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "2" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "from" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "to" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "value" (Json.Decode.string)

decodeSomethingRaw : Json.Decode.Decoder SomethingRaw
decodeSomethingRaw =
    Json.Decode.Pipeline.decode SomethingRaw
        |> Json.Decode.Pipeline.required "data" (Json.Decode.string)
        |> Json.Decode.Pipeline.required "topics" (Json.Decode.list Json.Decode.string)
