module LightBox exposing (..)

import Web3 exposing (Error)
import Web3.Eth exposing (defaultTxParams)
import Web3.Eth.Types exposing (Address, Abi, TxParams, Bytes, ContractInfo, TxId)
import Web3.Decoders exposing (bigIntDecoder, expectJson, expectString)
import Web3.Eth.Encoders exposing (txParamsEncoder)
import Web3.Eth.Contract as Contract
import Json.Encode as Encode exposing (int, string, object)
import Task exposing (Task)
import BigInt exposing (BigInt)


type alias Constructor =
    { someNum_ : BigInt }


abi : Abi
abi =
    """[{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"someNum","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"n","type":"int8"}],"name":"mutateAdd","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint8"},{"name":"b","type":"uint8"}],"name":"add","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"inputs":[{"name":"someNum_","type":"int8"}],"payable":true,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"mathematician","type":"address"},{"indexed":false,"name":"sum","type":"int8"}],"name":"Add","type":"event"}]"""


data : Bytes
data =
    """0x606060405260405160208061037e833981016040528080519060200190919050505b806000806101000a81548160ff021916908360000b60ff16021790555033600060016101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b505b6102ed806100916000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806341c0e1b51461006a5780634b76b19d1461007f5780635ca34539146100ae5780638da5cb5b146100ee578063bb4e3f4d14610143575b600080fd5b341561007557600080fd5b61007d61018f565b005b341561008a57600080fd5b6100926101cc565b604051808260000b60000b815260200191505060405180910390f35b34156100b957600080fd5b6100d2600480803560000b9060200190919050506101de565b604051808260000b60000b815260200191505060405180910390f35b34156100f957600080fd5b610101610288565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b341561014e57600080fd5b610173600480803560ff1690602001909190803560ff169060200190919050506102ae565b604051808260ff1660ff16815260200191505060405180910390f35b600060019054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16ff5b565b6000809054906101000a900460000b81565b6000816000808282829054906101000a900460000b0192506101000a81548160ff021916908360000b60ff1602179055503373ffffffffffffffffffffffffffffffffffffffff167fd0f15e1998f12f2dafbfd7cae1ba5399daa3a0da937ece55399590a101dcf5cb6000809054906101000a900460000b604051808260000b60000b815260200191505060405180910390a26000809054906101000a900460000b90505b919050565b600060019054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60008082840190508091505b50929150505600a165627a7a7230582063716296d7dd5d8d4eb1cde391a74b52e86cbaef310d67e79994b3eeef4178830029"""



-- metamask Mainnet gas Price == 156950
-- metamas Ropsten gas Price == 174290
-- testrpc gas price == 156799
--
-- Collisions will be possible between constructor names in someones solidity contract and values used elm
-- Mitigation needed during code generation. Last 6 chars of the abi's hash appended to constructor param names?


add : Address -> Int -> Int -> Task Error BigInt
add address a b =
    Web3.toTask
        { func = Contract.call abi "add" address
        , args = Encode.list [ int a, int b ]
        , expect = expectJson bigIntDecoder
        }


mutateAdd : Address -> Int -> Task Error TxId
mutateAdd address n =
    Web3.toTask
        { func = Contract.call abi "mutateAdd" address
        , args = Encode.list [ int n, txParamsEncoder defaultTxParams ]
        , expect = expectString
        }


new : Maybe BigInt -> Constructor -> Task Error ContractInfo
new value { someNum_ } =
    let
        constructorParams =
            [ Encode.string <| BigInt.toString someNum_ ]

        getData : Task Error Bytes
        getData =
            Contract.getData abi data constructorParams

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
