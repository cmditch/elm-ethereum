module LightBox exposing (..)

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Address, Abi, TxParams, TxData, NewContract)
import Web3.Eth.Contract
import Task exposing (Task)
import BigInt exposing (BigInt)


type alias Constructor =
    { someNum_ : BigInt }


abi : Abi
abi =
    """[{"constant":true,"inputs":[],"name":"someNum","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint8"},{"name":"b","type":"uint8"}],"name":"add","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"inputs":[{"name":"someNum_","type":"int8"}],"payable":true,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"mathematician","type":"address"},{"indexed":false,"name":"sum","type":"uint8"}],"name":"Add","type":"event"}]"""


data : TxData
data =
    """0x60606040526040516020806101b9833981016040528080519060200190919050505b806000806101000a81548160ff021916908360000b60ff1602179055505b505b610169806100506000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680634b76b19d14610049578063bb4e3f4d14610078575b600080fd5b341561005457600080fd5b61005c6100c4565b604051808260000b60000b815260200191505060405180910390f35b341561008357600080fd5b6100a8600480803560ff1690602001909190803560ff169060200190919050506100d6565b604051808260ff1660ff16815260200191505060405180910390f35b6000809054906101000a900460000b81565b60008082840190503373ffffffffffffffffffffffffffffffffffffffff167f94c48276ab473b3d25254c36e7fddc6b508c398c348e9ad44109c22abcd867bb82604051808260ff1660ff16815260200191505060405180910390a28091505b50929150505600a165627a7a723058205e5881dc088f2efc28610b639135409adcb27b2f75c702a03fd1c6fc0bf612270029"""



-- metamask gas Price == 156950 ?
-- testrpc gas price == 156799 ?
--
-- Collisions will be possible between constructor names in someones solidity contract and values used elm
-- Mitigation needed during code generation. Last 6 chars of the abi's hash appended to constructor param names?


new : Maybe BigInt -> Constructor -> Task Error NewContract
new value { someNum_ } =
    let
        value_ =
            Maybe.map BigInt.toString value
                |> Maybe.withDefault "0"

        ctorArg1 =
            BigInt.toString someNum_

        deployFunc =
            "eth.contract("
                ++ abi
                ++ ").new"
                ++ "("
                ++ ctorArg1
                ++ ", {from: "
                ++ "web3.eth.accounts[0]"
                ++ ", value: '"
                ++ value_
                ++ "', gas: "
                ++ "'2000000'"
                ++ ", data: '"
                ++ data
                ++ "'}, metaMaskCallBack )"
    in
        Web3.Eth.Contract.deployContract deployFunc
