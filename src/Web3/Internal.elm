module Web3.Internal
    exposing
        ( Request
        , Response
        , GetDataRequest
        , EventRequest
        , contractFuncHelper
        , expectStringResponse
        )

import Json.Encode as Encode exposing (Value)
import Web3.Types exposing (..)


type alias Request a =
    { func : String
    , args : Encode.Value
    , expect : Expect a
    , callType : CallType
    }


type alias GetDataRequest =
    { abi : Abi
    , data : Bytes
    , constructorParams : Value
    }


type alias EventRequest =
    { abi : Abi
    , address : Address
    , argsFilter : Value
    , filterParams : Value
    , eventName : String
    }


type alias Response =
    String


expectStringResponse : (Response -> Result String a) -> Expect a
expectStringResponse =
    Native.Web3.expectStringResponse


contractFuncHelper : Abi -> Address -> String -> String
contractFuncHelper (Abi abi) (Address address) func =
    "eth.contract("
        ++ abi
        ++ ").at('"
        ++ address
        ++ "')."
        ++ func
