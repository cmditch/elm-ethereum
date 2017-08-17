module LightBox exposing (..)

import Task exposing (Task)
import BigInt exposing (BigInt)
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Web3
import Web3.Types exposing (..)
import Web3.Eth exposing (defaultTxParams)
import Web3.Eth.Contract as Contract
import Web3.Encoders exposing (..)
import Web3.Decoders exposing (..)


{-
    Let this serve as a template for how elm contract interfaces will be designed

   TODO Collisions will be possible between constructor names in someones solidity contract and values used elm
   Mitigation needed during code generation. Last 6 chars of the abi's hash appended to constructor param names?

-}
{-
   Core Contract info : ABI and Bytecode
-}


type alias Constructor =
    { someNum_ : BigInt }


lightBoxAbi_ : Abi
lightBoxAbi_ =
    Abi """[{"constant":false,"inputs":[],"name":"uintArray","outputs":[{"name":"","type":"uint256[23]"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"otherNum","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"n","type":"uint256"}],"name":"mutateSubtract","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint8"},{"name":"b","type":"uint8"}],"name":"add_","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"someNum","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"n","type":"int8"}],"name":"mutateAdd","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"uintArray","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"inputs":[{"name":"someNum_","type":"int8"}],"payable":true,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"mathematician","type":"address"},{"indexed":false,"name":"sum","type":"int8"}],"name":"Add","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"professor","type":"address"},{"indexed":false,"name":"numberz","type":"uint256"},{"indexed":false,"name":"aPrime","type":"int256"}],"name":"Subtract","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"uintArray","type":"uint256[23]"}],"name":"UintArray","type":"event"}]"""


lightBoxBytecode_ : Bytes
lightBoxBytecode_ =
    Bytes """60606040526102e060405190810160405280691a128493b237654ff3b36affffffffffffffffffffff168152602001607c6affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681526020016a0a2f3bc9b0f19288d073b36affffffffffffffffffffff168152602001602b6affffffffffffffffffffff168152602001691a128493b237654ff3b36affffffffffffffffffffff16815260200162158d476affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681526020016102916affffffffffffffffffffff168152602001602a6affffffffffffffffffffff16815260200160046affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681526020016a65d82a82b536f8a7cff3b36affffffffffffffffffffff1681526020016102f46affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681526020016102916affffffffffffffffffffff168152602001691a128493b237654ff3b36affffffffffffffffffffff16815260200161071f6affffffffffffffffffffff16815260200161316d6affffffffffffffffffffff168152602001607b6affffffffffffffffffffff16815260200161050d6affffffffffffffffffffff1681526020016130446affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681525060039060176102239291906102a6565b506040516020806108ed833981016040528080519060200190919050505b806000806101000a81548160ff021916908360000b60ff16021790555033600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b5061031a565b82601781019282156102e4579160200282015b828111156102e357825182906affffffffffffffffffffff169055916020019190600101906102b9565b5b5090506102f191906102f5565b5090565b61031791905b808211156103135760008160009055506001016102fb565b5090565b90565b6105c4806103296000396000f30060606040523615610097576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff168063199f31161461009c5780631c761abb146100ee5780631eda76db14610117578063301fe0031461014e57806341c0e1b51461019a5780634b76b19d146101af5780635ca34539146101de5780638da5cb5b1461021e5780639ae918c714610273575b600080fd5b34156100a757600080fd5b6100af6102aa565b6040518082601760200280838360005b838110156100db5780820151818401525b6020810190506100bf565b5050505090500191505060405180910390f35b34156100f957600080fd5b61010161034e565b6040518082815260200191505060405180910390f35b341561012257600080fd5b6101386004808035906020019091905050610354565b6040518082815260200191505060405180910390f35b341561015957600080fd5b61017e600480803560ff1690602001909190803560ff169060200190919050506103ca565b604051808260ff1660ff16815260200191505060405180910390f35b34156101a557600080fd5b6101ad6103dd565b005b34156101ba57600080fd5b6101c261041a565b604051808260000b60000b815260200191505060405180910390f35b34156101e957600080fd5b610202600480803560000b90602001909190505061042c565b604051808260000b60000b815260200191505060405180910390f35b341561022957600080fd5b61023161052e565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b341561027e57600080fd5b6102946004808035906020019091905050610554565b6040518082815260200191505060405180910390f35b6102b261056f565b7f7aec1d84330019f43b634453d28c53b7049325ab10c0189e2fef09725902c95160036040518082601780156102fd576020028201915b8154815260200190600101908083116102e9575b505091505060405180910390a16003601780602002604051908101604052809291908260178015610343576020028201915b81548152602001906001019080831161032f575b505050505090505b90565b60015481565b6000816001600082825401925050819055503373ffffffffffffffffffffffffffffffffffffffff167f8a272b2843aeeb96e1c8a9726cd50e60bdb87c015ee0c8429e591f65e77b48576001546017604051808381526020018281526020019250505060405180910390a260015490505b919050565b60008082840190508091505b5092915050565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16ff5b565b6000809054906101000a900460000b81565b6000816000808282829054906101000a900460000b0192506101000a81548160ff021916908360000b60ff1602179055507f7aec1d84330019f43b634453d28c53b7049325ab10c0189e2fef09725902c95160036040518082601780156104a8576020028201915b815481526020019060010190808311610494575b505091505060405180910390a13373ffffffffffffffffffffffffffffffffffffffff167fd0f15e1998f12f2dafbfd7cae1ba5399daa3a0da937ece55399590a101dcf5cb6000809054906101000a900460000b604051808260000b60000b815260200191505060405180910390a26000809054906101000a900460000b90505b919050565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60038160178110151561056357fe5b0160005b915090505481565b6102e0604051908101604052806017905b600081526020019060019003908161058057905050905600a165627a7a7230582023e5ca95c09f251b2e4533c8ab621f56ae413a1e68200d1ce33e7487d2b1cf3a0029"""



{-
   Contract Functions
-}


add_ : Address -> Int -> Int -> Task Error BigInt
add_ address a b =
    Web3.toTask
        { func = Contract.call lightBoxAbi_ address "add_"
        , args = Encode.list [ Encode.int a, Encode.int b ]
        , expect = expectJson bigIntDecoder
        , callType = Async
        }


mutateAdd : Address -> Int -> Task Error TxId
mutateAdd address n =
    Web3.toTask
        { func = Contract.call lightBoxAbi_ address "mutateAdd"
        , args = Encode.list [ Encode.int n, encodeTxParams defaultTxParams ]
        , expect = expectJson txIdDecoder
        , callType = Async
        }



{-
   Contract Factory
-}


new_ : Maybe BigInt -> Constructor -> Task Error ContractInfo
new_ value { someNum_ } =
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
            Task.map2 (\data gasCost -> { defaultTxParams | data = Just data, gas = Just gasCost, value = value, from = Just (Address "0xe87529a6123a74320e13a6dabf3606630683c029") })
    in
        buildTransaction getData estimateGas
            |> Task.andThen Web3.Eth.sendTransaction
            |> Task.andThen (Contract.pollContract { attempts = 30, sleep = 3 })



{-
   TODO
   Each event will have:
     type alias : EventArgs, EventFilters
     functions : defaultEventFilter, watchEvent, getEvent
     encodeEventFilters, decodeEventArgs, decodeEventEventLog

-}
-- EVENTS


type Event
    = Add AddFilter FilterParams
    | Subtract SubtractFilter FilterParams
    | UintArray UintArrayFilter FilterParams


watch_ : Event -> Address -> String -> Cmd msg
watch_ eventParams address name =
    let
        ( name_, argsFilter_, filterParams_ ) =
            case eventParams of
                Add argsFilter filterParams ->
                    ( "Add"
                    , encodeAdd_ argsFilter
                    , encodeFilterParams filterParams
                    )

                Subtract argsFilter filterParams ->
                    ( "Subtract"
                    , encodeSubtract_ argsFilter
                    , encodeFilterParams filterParams
                    )

                UintArray argsFilter filterParams ->
                    ( "Subtract"
                    , encodeUintArray_ argsFilter
                    , encodeFilterParams filterParams
                    )
    in
        Contract.watch name
            { abi = lightBoxAbi_
            , address = address
            , argsFilter = argsFilter_
            , filterParams = filterParams_
            , eventName = name_
            }


get_ :
    Decoder log
    -> Event
    -> Address
    -> Task Error (List log)
get_ decoder eventParams address =
    let
        ( name_, argsFilter_, filterParams_ ) =
            case eventParams of
                Add argsFilter filterParams ->
                    ( "Add"
                    , encodeAdd_ argsFilter
                    , encodeFilterParams filterParams
                    )

                Subtract argsFilter filterParams ->
                    ( "Subtract"
                    , encodeSubtract_ argsFilter
                    , encodeFilterParams filterParams
                    )

                UintArray argsFilter filterParams ->
                    ( "Subtract"
                    , encodeUintArray_ argsFilter
                    , encodeFilterParams filterParams
                    )
    in
        Contract.get decoder
            { abi = lightBoxAbi_
            , address = address
            , argsFilter = argsFilter_
            , filterParams = filterParams_
            , eventName = "Add"
            }


stopWatching_ : String -> Cmd msg
stopWatching_ =
    Contract.stopWatching


sentry_ : String -> (String -> msg) -> Sub msg
sentry_ =
    Contract.sentry


reset_ : Cmd msg
reset_ =
    Contract.reset



-- EVENT HELPERS
{-
   Add(mathematician indexed address, sum int8)
-}


type alias AddArgs =
    { mathematician : Address, sum : BigInt }


type alias AddFilter =
    { mathematician : Maybe (List Address)
    , sum : Maybe (List Int)
    }


addFilter_ : AddFilter
addFilter_ =
    { mathematician = Nothing, sum = Nothing }


encodeAdd_ : AddFilter -> Value
encodeAdd_ { mathematician, sum } =
    listOfMaybesToVal
        [ ( "mathematician", Maybe.map encodeAddressList mathematician )
        , ( "sum", Maybe.map encodeIntList sum )
        ]


decodeAdd_ : Decoder AddArgs
decodeAdd_ =
    decode AddArgs
        |> required "mathematician" addressDecoder
        |> required "sum" bigIntDecoder


decodeAddLog_ : Decoder (EventLog AddArgs)
decodeAddLog_ =
    eventLogDecoder decodeAdd_



{-
   Subtract(address indexed professor, uint numberz, int aPrime)
-}


type alias SubtractArgs =
    { professor : Address, numberz : BigInt, aPrime : BigInt }


type alias SubtractFilter =
    { professor : Maybe (List Address)
    , numberz : Maybe (List BigInt)
    , aPrime : Maybe (List BigInt)
    }


subtractFilter_ : SubtractFilter
subtractFilter_ =
    { professor = Nothing, numberz = Nothing, aPrime = Nothing }


encodeSubtract_ : SubtractFilter -> Value
encodeSubtract_ { professor, numberz, aPrime } =
    listOfMaybesToVal
        [ ( "professor", Maybe.map encodeAddressList professor )
        , ( "numberz", Maybe.map encodeBigIntList numberz )
        , ( "aPrime", Maybe.map encodeBigIntList aPrime )
        ]


decodeSubtract_ : Decoder SubtractArgs
decodeSubtract_ =
    decode SubtractArgs
        |> required "professor" addressDecoder
        |> required "numberz" bigIntDecoder
        |> required "aPrime" bigIntDecoder


decodeSubtractLog_ : Decoder (EventLog SubtractArgs)
decodeSubtractLog_ =
    eventLogDecoder decodeSubtract_



{-
   UintArray(uint[23] uintArray)
-}


type alias UintArrayArgs =
    { uintArray : List BigInt }


type alias UintArrayFilter =
    { uintArray : Maybe (List (List BigInt)) }


uintArrayFilter_ : UintArrayFilter
uintArrayFilter_ =
    { uintArray = Nothing }


encodeUintArray_ : UintArrayFilter -> Value
encodeUintArray_ { uintArray } =
    listOfMaybesToVal
        [ ( "uintArray", Maybe.map encodeListBigIntList uintArray ) ]


uintArrayDecoder_ : Decoder UintArrayArgs
uintArrayDecoder_ =
    decode UintArrayArgs
        |> required "uintArray" (Decode.list bigIntDecoder)


decodeUintArrayLog_ : Decoder (EventLog UintArrayArgs)
decodeUintArrayLog_ =
    eventLogDecoder uintArrayDecoder_
