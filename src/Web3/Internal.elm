module Web3.Internal
    exposing
        ( Request
        , Response
        , EventRequest
        , expectStringResponse
        )

import Json.Encode as Encode exposing (Value)
import Web3.Types exposing (Expect(..), CallType(..))
import Web3.Eth.Types exposing (Abi, Address)


type alias Request a =
    { func : String
    , args : Encode.Value
    , expect : Expect a
    , callType : CallType
    }


type alias EventRequest =
    { abi : Abi
    , address : Address
    , filterParams : Value
    , eventParams : Value
    , portName : Value
    , eventName : String
    }


type alias Response =
    String


expectStringResponse : (Response -> Result String a) -> Expect a
expectStringResponse =
    Native.Web3.expectStringResponse
