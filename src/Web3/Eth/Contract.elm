module Web3.Eth.Contract
    exposing
        ( CallData
        , call
        , sendTransaction
        )

import Web3 exposing (Address, Error)
import Task exposing (Task)
import Json.Encode exposing (Value)
import BigInt exposing (BigInt)


type alias CallData =
    { abi : Value
    , address : Address
    , args : Maybe Value
    }


type alias SendData =
    { abi : Value
    , address : Address
    , params : TxParams
    , args : Maybe (List Value)
    , data : Maybe String
    }


type alias TxParams =
    { from : Address
    , value : Maybe BigInt
    , gas : Maybe BigInt
    , data : Maybe TxData
    }


type alias TxData =
    String


call : Result Error a -> CallData -> Task Error a
call msg data =
    Native.Web3.toTask


sendTransaction : Result Error a -> SendData -> Task Error a
sendTransaction msg data =
    Native.Web3.toTask
