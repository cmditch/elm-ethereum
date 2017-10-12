module TestContract exposing (..)

import BigInt exposing (BigInt)
import Json.Decode as Decode exposing (Decoder, int, string)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Json.Encode as Encode exposing (Value)
import Web3.Types exposing (..)
import Web3
import Web3.Eth.Contract as Contract
import Web3.Eth as Eth
import Web3.Decoders exposing (..)
import Task exposing (Task)


{-
   Core Contract info : ABI and Bytecode
-}


type alias Constructor =
    { constructorInt_ : BigInt, constructorString_ : String }


deploy : Address -> Maybe BigInt -> BigInt -> String -> Task Error ContractInfo
deploy from value constructorInt_ constructorString_ =
    let
        failIfNothing maybeVal error =
            case maybeVal of
                Nothing ->
                    Task.fail error

                Just txReceipt ->
                    Task.succeed txReceipt
    in
        estimateContractGas constructorInt_ constructorString_
            |> Task.andThen
                (\gasCost ->
                    encodeContractABI constructorInt_ constructorString_
                        |> Task.andThen
                            (\data ->
                                Eth.sendTransaction from
                                    { to = Nothing
                                    , value = value
                                    , gas = gasCost + 753410 -- TODO WTF
                                    , data = Just data
                                    , gasPrice = Just gasCost
                                    , chainId = Nothing
                                    , nonce = Nothing
                                    }
                            )
                )
            |> Task.andThen Eth.getTransactionReceipt
            |> Task.andThen
                (\maybeTxReceipt ->
                    Web3.retry { attempts = 30, sleep = 3 }
                        (failIfNothing maybeTxReceipt (Error "No Tx Receipt still. Mining error. Network Congestion?"))
                )
            |> Task.andThen
                (\receipt ->
                    case receipt.contractAddress of
                        Nothing ->
                            Task.fail (Error "No contract address in Tx Receipt. This error should never happen...")

                        Just contractAddress ->
                            Task.succeed { txId = receipt.transactionHash, address = contractAddress }
                )


encodeContractABI : BigInt -> String -> Task Error Hex
encodeContractABI constructorInt_ constructorString_ =
    Contract.encodeContractABI
        { abi = abi_
        , gasPrice = Nothing
        , gas = Nothing
        , methodName = Nothing
        , data = Just bytecode_
        , params = [ Encode.string <| BigInt.toString constructorInt_, Encode.string constructorString_ ]
        , decoder = hexDecoder
        }


estimateContractGas : BigInt -> String -> Task Error Int
estimateContractGas constructorInt_ constructorString_ =
    Contract.estimateContractGas
        { abi = abi_
        , gasPrice = Nothing
        , gas = Nothing
        , methodName = Nothing
        , data = Just bytecode_
        , params = [ Encode.string <| BigInt.toString constructorInt_, Encode.string constructorString_ ]
        , decoder = int
        }


abi_ : Abi
abi_ =
    Abi """[{"constant":true,"inputs":[],"name":"otherNum","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsTwoUnnamed","outputs":[{"name":"","type":"uint256"},{"name":"","type":"string"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"anInt","type":"int256"}],"name":"triggerEvent","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsOneNamed","outputs":[{"name":"someNumber","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"uintArray","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"mutableInt","outputs":[{"name":"","type":"int256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"constructorString","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsTwoNamed","outputs":[{"name":"someUint","type":"uint256"},{"name":"someString","type":"string"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsOneUnnamed","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[{"name":"constructorInt_","type":"int256"},{"name":"constructorString_","type":"string"}],"payable":true,"stateMutability":"payable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"mathematician","type":"address"},{"indexed":false,"name":"anInt","type":"int256"}],"name":"Add","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"professor","type":"address"},{"indexed":false,"name":"numberz","type":"uint256"},{"indexed":false,"name":"aPrime","type":"int256"}],"name":"Subtract","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"uintArrayLog","type":"uint256[4]"}],"name":"UintArray","type":"event"}]"""


bytecode_ : Hex
bytecode_ =
    Hex """0x6060604052608060405190810160405280656ffad60473b365ffffffffffff168152602001601765ffffffffffff168152602001602a65ffffffffffff168152602001607865ffffffffffff16815250600490600461005f9291906100eb565b50604051610965380380610965833981016040528080519060200190919080518201919050508160008190555080600190805190602001906100a2929190610135565b5033600360006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050506101da565b8260048101928215610124579160200282015b82811115610123578251829065ffffffffffff169055916020019190600101906100fe565b5b50905061013191906101b5565b5090565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061017657805160ff19168380011785556101a4565b828001600101855582156101a4579182015b828111156101a3578251825591602001919060010190610188565b5b5090506101b191906101b5565b5090565b6101d791905b808211156101d35760008160009055506001016101bb565b5090565b90565b61077c806101e96000396000f300606060405236156100ad576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680631c761abb146100b257806328985c17146100db5780633840369b1461018757806341c0e1b51461022357806386231246146102385780638da5cb5b146102785780639ae918c7146102cd578063b4e70e6e14610304578063bcdf89a41461032d578063c43a6a79146103bb578063ed1a9ca114610467575b600080fd5b34156100bd57600080fd5b6100c56104a7565b6040518082815260200191505060405180910390f35b34156100e657600080fd5b61010560048080359060200190919080359060200190919050506104ad565b6040518083815260200180602001828103825283818151815260200191508051906020019080838360005b8381101561014b578082015181840152602081019050610130565b50505050905090810190601f1680156101785780820380516001836020036101000a031916815260200191505b50935050505060405180910390f35b341561019257600080fd5b6101a860048080359060200190919050506104fb565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156101e85780820151818401526020810190506101cd565b50505050905090810190601f1680156102155780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b341561022e57600080fd5b6102366105b5565b005b341561024357600080fd5b61026260048080359060200190919080359060200190919050506105f0565b6040518082815260200191505060405180910390f35b341561028357600080fd5b61028b6105fd565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34156102d857600080fd5b6102ee6004808035906020019091905050610623565b6040518082815260200191505060405180910390f35b341561030f57600080fd5b61031761063d565b6040518082815260200191505060405180910390f35b341561033857600080fd5b610340610643565b6040518080602001828103825283818151815260200191508051906020019080838360005b83811015610380578082015181840152602081019050610365565b50505050905090810190601f1680156103ad5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34156103c657600080fd5b6103e560048080359060200190919080359060200190919050506106e1565b6040518083815260200180602001828103825283818151815260200191508051906020019080838360005b8381101561042b578082015181840152602081019050610410565b50505050905090810190601f1680156104585780820380516001836020036101000a031916815260200191505b50935050505060405180910390f35b341561047257600080fd5b610491600480803590602001909190803590602001909190505061072f565b6040518082815260200191505060405180910390f35b60025481565b60006104b761073c565b8284016040805190810160405280600e81526020017f5468697320697320612074657374000000000000000000000000000000000000815250915091509250929050565b61050361073c565b3373ffffffffffffffffffffffffffffffffffffffff167f6da406ea462447ed7804b4a4dc69c67b53d3d45a50381ae3e9cf878c9d7c23df836040518082815260200191505060405180910390a2606060405190810160405280602681526020017f546869732073686f756c642068617665207472696767657265642061206c6f6781526020017f206576656e7400000000000000000000000000000000000000000000000000008152509050919050565b600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16ff5b6000818301905092915050565b600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60048160048110151561063257fe5b016000915090505481565b60005481565b60018054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156106d95780601f106106ae576101008083540402835291602001916106d9565b820191906000526020600020905b8154815290600101906020018083116106bc57829003601f168201915b505050505081565b60006106eb61073c565b8284016040805190810160405280600e81526020017f5468697320697320612074657374000000000000000000000000000000000000815250915091509250929050565b6000818301905092915050565b6020604051908101604052806000815250905600a165627a7a72305820ad1eec0ce6ab1a5db5353fcedd4ac7132d4d713ec26efad19b3b24f452774d500029"""


returnsOneNamed : BigInt -> BigInt -> Contract.Params BigInt
returnsOneNamed a b =
    { abi = abi_
    , gasPrice = Just (BigInt.fromInt 300000000)
    , gas = Just 3000000
    , methodName = Just "returnsOneNamed(uint256,uint256)"
    , data = Nothing
    , params = [ Encode.string (BigInt.toString a), Encode.string (BigInt.toString b) ]
    , decoder = bigIntDecoder
    }


returnsOneUnnamed : BigInt -> BigInt -> Contract.Params BigInt
returnsOneUnnamed a b =
    { abi = abi_
    , gasPrice = Just (BigInt.fromInt 300000000)
    , gas = Just 3000000
    , methodName = Just "returnsOneUnnamed(uint256,uint256)"
    , data = Nothing
    , params = [ Encode.string (BigInt.toString a), Encode.string (BigInt.toString b) ]
    , decoder = bigIntDecoder
    }


returnsTwoNamed : BigInt -> BigInt -> Contract.Params { someUint : BigInt, someString : String }
returnsTwoNamed a b =
    let
        decoder =
            decode (\someUint someString -> { someUint = someUint, someString = someString })
                |> required "someUint" bigIntDecoder
                |> required "someString" string
    in
        { abi = abi_
        , gasPrice = Just (BigInt.fromInt 300000000)
        , gas = Just 300000
        , methodName = Just "returnsTwoNamed(uint256,uint256)"
        , data = Nothing
        , params = [ Encode.string (BigInt.toString a), Encode.string (BigInt.toString b) ]
        , decoder = decoder
        }


returnsTwoUnnamed : BigInt -> BigInt -> Contract.Params { v0 : BigInt, v1 : String }
returnsTwoUnnamed a b =
    let
        decoder =
            decode (\v0 v1 -> { v0 = v0, v1 = v1 })
                |> required "0" bigIntDecoder
                |> required "1" string
    in
        { abi = abi_
        , gasPrice = Just (BigInt.fromInt 300000000)
        , gas = Just 3000000
        , methodName = Just "returnsTwoUnnamed(uint256,uint256)"
        , data = Nothing
        , params = [ Encode.string (BigInt.toString a), Encode.string (BigInt.toString b) ]
        , decoder = decoder
        }
