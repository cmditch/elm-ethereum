module LightBox exposing (..)

import Web3 exposing (Error)
import Web3.Types exposing (..)
import Web3.Eth exposing (defaultTxParams)
import Web3.Eth.Types exposing (..)
import Web3.Decoders exposing (bigIntDecoder, expectJson, expectString)
import Web3.Eth.Encoders exposing (txParamsEncoder, filterParamsEncoder)
import Web3.Eth.Decoders exposing (eventLogDecoder)
import Web3.Eth.Contract as Contract
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional)
import BigInt exposing (BigInt)
import Task exposing (Task)


{-
   Core Contract info : ABI and Bytecode

   Collisions will be possible between constructor names in someones solidity contract and values used elm
   Mitigation needed during code generation. Last 6 chars of the abi's hash appended to constructor param names?
-}


type alias Constructor =
    { someNum_ : BigInt }


lightBoxAbi_ : Abi
lightBoxAbi_ =
    """[{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"someNum","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"n","type":"int8"}],"name":"mutateAdd","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint8"},{"name":"b","type":"uint8"}],"name":"add","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"inputs":[{"name":"someNum_","type":"int8"}],"payable":true,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"mathematician","type":"address"},{"indexed":false,"name":"sum","type":"int8"}],"name":"Add","type":"event"}]"""


lightBoxBytecode_ : Bytes
lightBoxBytecode_ =
    """0x606060405260405160208061037e833981016040528080519060200190919050505b806000806101000a81548160ff021916908360000b60ff16021790555033600060016101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b505b6102ed806100916000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806341c0e1b51461006a5780634b76b19d1461007f5780635ca34539146100ae5780638da5cb5b146100ee578063bb4e3f4d14610143575b600080fd5b341561007557600080fd5b61007d61018f565b005b341561008a57600080fd5b6100926101cc565b604051808260000b60000b815260200191505060405180910390f35b34156100b957600080fd5b6100d2600480803560000b9060200190919050506101de565b604051808260000b60000b815260200191505060405180910390f35b34156100f957600080fd5b610101610288565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b341561014e57600080fd5b610173600480803560ff1690602001909190803560ff169060200190919050506102ae565b604051808260ff1660ff16815260200191505060405180910390f35b600060019054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16ff5b565b6000809054906101000a900460000b81565b6000816000808282829054906101000a900460000b0192506101000a81548160ff021916908360000b60ff1602179055503373ffffffffffffffffffffffffffffffffffffffff167fd0f15e1998f12f2dafbfd7cae1ba5399daa3a0da937ece55399590a101dcf5cb6000809054906101000a900460000b604051808260000b60000b815260200191505060405180910390a26000809054906101000a900460000b90505b919050565b600060019054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008082840190508091505b50929150505600a165627a7a7230582063716296d7dd5d8d4eb1cde391a74b52e86cbaef310d67e79994b3eeef4178830029"""



{-
   Contract Functions
-}


add : Address -> Int -> Int -> Task Error BigInt
add address a b =
    Web3.toTask
        { func = Contract.call lightBoxAbi_ "add" address
        , args = Encode.list [ Encode.int a, Encode.int b ]
        , expect = expectJson bigIntDecoder
        , callType = Async
        }


mutateAdd : Address -> Int -> Task Error TxId
mutateAdd address n =
    Web3.toTask
        { func = Contract.call lightBoxAbi_ "mutateAdd" address
        , args = Encode.list [ Encode.int n, txParamsEncoder defaultTxParams ]
        , expect = expectString
        , callType = Async
        }



{-
   Contract Factory
-}


new : Maybe BigInt -> Constructor -> Task Error ContractInfo
new value { someNum_ } =
    let
        constructorParams =
            [ Encode.string <| BigInt.toString someNum_ ]

        getData : Task Error Bytes
        getData =
            Contract.getData lightBoxAbi_ lightBoxBytecode_ constructorParams

        estimateGas : Task Error Int
        estimateGas =
            Task.map (\data -> { defaultTxParams | data = Just data }) getData
                |> Task.andThen Web3.Eth.estimateGas

        buildTransaction : Task Error Bytes -> Task Error Int -> Task Error TxParams
        buildTransaction =
            Task.map2 (\data gasCost -> { defaultTxParams | data = Just data, gas = Just gasCost, value = value })
    in
        buildTransaction getData estimateGas
            |> Task.andThen Web3.Eth.sendTransaction
            |> Task.andThen (Contract.pollContract { attempts = 30, sleep = 3 })



{-
   Events

   Each event is defined by a constructor within the union-type PortName.
   This union-type is probably the only thing in this file that should be edited by the user,
   and should sit at the very top of the file above the clearly marked "do not touch" section.

   This constructor names must match it's decapitalized version within your ports definition.
   see Port.elm
-}


type Event
    = Add


type PortNameAndEvent
    = WatchAdd Event



{-
   Each event will have:
    type alias : EventArgs, RawEventArgs, EventFilters
    functions : defaultEventFilter, watchEvent, stopWatchingEvent, getEvent
    encodeEventFilters, decodeEventArgs, decodeEventEventLog

-}
-- event Add(mathematician indexed address, sum int8) helpers


type alias AddArgs =
    { mathematician : Address, sum : BigInt }


type alias RawAddArgs =
    { mathematician : Address, sum : String }


type alias AddFilters =
    { mathematician : Maybe Address, sum : Maybe Int }


defaultAddFilter : AddFilters
defaultAddFilter =
    { mathematician = Nothing, sum = Nothing }



-- TODO I'm thinking we have a watch/get/stop function for each event,
--      Otherwise the wrong stringy eventName could be passed by the user in their update/Task.attempt
--      Having a more general watch function would be much less code,
--        but might dangerously subvert the compiler guarantees.
--      Unless... each PortName came parameterized with an Event,
--        with Event being a union-type of event names... hrmm. Up for review.
--


watchAdd : FilterParams -> AddFilters -> Address -> PortNameAndEvent -> Task Error ()
watchAdd filterParams eventParams address portNameAndEvent =
    let
        filterParams_ =
            filterParamsEncoder filterParams

        eventParams_ =
            encodeAddFilter eventParams

        portNameAndEvent_ =
            toString portNameAndEvent
                |> Encode.string
    in
        Contract.watch
            { abi = lightBoxAbi_
            , address = address
            , filterParams = filterParams_
            , eventParams = eventParams_
            , portNameAndEvent = portNameAndEvent_
            }


encodeAddFilter : AddFilters -> Value
encodeAddFilter { mathematician, sum } =
    [ ( "mathematician", Maybe.map Encode.string mathematician )
    , ( "sum", Maybe.map Encode.int sum )
    ]
        |> List.filter (\( k, v ) -> v /= Nothing)
        |> List.map (\( k, v ) -> ( k, Maybe.withDefault Encode.null v ))
        |> Encode.object


decodeAddArgs : Decoder AddArgs
decodeAddArgs =
    decode AddArgs
        |> required "mathematician" Decode.string
        |> required "sum" bigIntDecoder


decodeAddEventLog : Decoder (EventLog AddArgs)
decodeAddEventLog =
    eventLogDecoder decodeAddArgs



-- formatRawEvent : Incoming port value -> Model value
{- TODO
   Question is:
      Do we use Maybe.withDefault, or make the user deal with a Maybe BigInt
      for all EventLog's with BigNumber.js types.
      I think withDefault is fairly safe here. We're parsing their ABI,
      so we know anything returning an int or uint will be turned into BigNumbers.
      The withDefault failure should never occur.
      I think we need to choose a number, like -1 or -42, and make it explicit in the docs,
      that if you see this number during tests, something errory has occured.
-}


formatAddEventLog : EventLog RawAddArgs -> EventLog AddArgs
formatAddEventLog event =
    let
        { args } =
            event

        formatedArgs =
            { args
                | sum =
                    BigInt.fromString args.sum
                        |> Maybe.withDefault (BigInt.fromInt -42)
            }
    in
        { event | args = formatedArgs }
