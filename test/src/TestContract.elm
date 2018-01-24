module TestContract exposing (..)

import Web3
import BigInt as BI exposing (BigInt)
import Json.Decode.Pipeline exposing (decode, required)
import Json.Decode as D
import Json.Encode as E
import Web3.Decoders as D
import Web3.Encoders as E
import Web3.Types exposing (..)
import Web3.Eth.Contract as Contract
import Web3.Eth as Eth
import Task exposing (Task)


abi_ : Abi
abi_ =
    Abi
        """[{"constant":true,"inputs":[],"name":"otherNum","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsTwoUnnamed","outputs":[{"name":"","type":"uint256"},{"name":"","type":"string"}],"payable":false,"stateMutability":"pure","type":"function"},{"constant":false,"inputs":[{"name":"anInt","type":"int256"}],"name":"triggerEvent","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsOneNamed","outputs":[{"name":"someNumber","type":"uint256"}],"payable":false,"stateMutability":"pure","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"uintArray","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"mutableInt","outputs":[{"name":"","type":"int256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"constructorString","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsTwoNamed","outputs":[{"name":"someUint","type":"uint256"},{"name":"someString","type":"string"}],"payable":false,"stateMutability":"pure","type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsOneUnnamed","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"pure","type":"function"},{"inputs":[{"name":"constructorInt_","type":"int256"},{"name":"constructorString_","type":"string"}],"payable":true,"stateMutability":"payable","type":"constructor"},{"payable":false,"stateMutability":"nonpayable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"mathematician","type":"address"},{"indexed":false,"name":"anInt","type":"int256"}],"name":"Add","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"professor","type":"address"},{"indexed":false,"name":"numberz","type":"uint256"},{"indexed":false,"name":"aPrime","type":"int256"}],"name":"Subtract","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"uintArrayLog","type":"uint256[4]"}],"name":"UintArray","type":"event"}]"""


type alias Constructor =
    { constructorInt_ : BigInt, constructorString_ : String }


constructorString : Contract.Params String
constructorString =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "constructorString()"
    , data = Nothing
    , params = []
    , decoder = D.string
    }


kill : Contract.Params ()
kill =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "kill()"
    , data = Nothing
    , params = []
    , decoder = D.succeed ()
    }


mutableInt : Contract.Params BigInt
mutableInt =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "mutableInt()"
    , data = Nothing
    , params = []
    , decoder = D.bigIntDecoder
    }


otherNum : Contract.Params BigInt
otherNum =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "otherNum()"
    , data = Nothing
    , params = []
    , decoder = D.bigIntDecoder
    }


owner : Contract.Params Address
owner =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "owner()"
    , data = Nothing
    , params = []
    , decoder = D.addressDecoder
    }


returnsOneNamed : BigInt -> BigInt -> Contract.Params BigInt
returnsOneNamed a b =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "returnsOneNamed(uint256,uint256)"
    , data = Nothing
    , params = [ E.encodeBigInt a, E.encodeBigInt b ]
    , decoder = D.bigIntDecoder
    }


returnsOneUnnamed : BigInt -> BigInt -> Contract.Params BigInt
returnsOneUnnamed a b =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "returnsOneUnnamed(uint256,uint256)"
    , data = Nothing
    , params = [ E.encodeBigInt a, E.encodeBigInt b ]
    , decoder = D.bigIntDecoder
    }


returnsTwoNamed : BigInt -> BigInt -> Contract.Params { someUint : BigInt, someString : String }
returnsTwoNamed a b =
    let
        decoder =
            decode (\someUint someString -> { someUint = someUint, someString = someString })
                |> required "someUint" D.bigIntDecoder
                |> required "someString" D.string
    in
        { abi = abi_
        , gasPrice = Just (BI.fromInt 300000000)
        , gas = Just 300000
        , methodName = Just "returnsTwoNamed(uint256,uint256)"
        , data = Nothing
        , params = [ E.encodeBigInt a, E.encodeBigInt b ]
        , decoder = decoder
        }


returnsTwoUnnamed : BigInt -> BigInt -> Contract.Params { v0 : BigInt, v1 : String }
returnsTwoUnnamed a b =
    let
        decoder =
            decode (\v0 v1 -> { v0 = v0, v1 = v1 })
                |> required "0" D.bigIntDecoder
                |> required "1" D.string
    in
        { abi = abi_
        , gasPrice = Just (BI.fromInt 300000000)
        , gas = Just 300000
        , methodName = Just "returnsTwoUnnamed(uint256,uint256)"
        , data = Nothing
        , params = [ E.encodeBigInt a, E.encodeBigInt b ]
        , decoder = decoder
        }


triggerEvent : BigInt -> Contract.Params String
triggerEvent anInt =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "triggerEvent(int256)"
    , data = Nothing
    , params = [ E.encodeBigInt anInt ]
    , decoder = D.string
    }


uintArray : BigInt -> Contract.Params BigInt
uintArray a =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "uintArray(uint256)"
    , data = Nothing
    , params = [ E.encodeBigInt a ]
    , decoder = D.bigIntDecoder
    }



{- Add event -}


subscribeAdd : ( Address, EventId ) -> Cmd msg
subscribeAdd =
    Contract.subscribe abi_ "Add"


onceAdd : Contract.Params (EventLog { mathematician : Address, anInt : BigInt })
onceAdd =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "Add"
    , data = Nothing
    , params = []
    , decoder = addDecoder
    }


decodeAdd : String -> Result Error (EventLog { mathematician : Address, anInt : BigInt })
decodeAdd response =
    response
        |> D.decodeString addDecoder
        |> Result.mapError (\e -> Error e)


addDecoder =
    decode (\mathematician anInt -> { mathematician = mathematician, anInt = anInt })
        |> required "mathematician" D.addressDecoder
        |> required "anInt" D.bigIntDecoder



{- Subtract event -}


subscribeSubtract : ( Address, EventId ) -> Cmd msg
subscribeSubtract =
    Contract.subscribe abi_ "Subtract"


onceSubtract : Contract.Params (EventLog { professor : Address, numberz : BigInt, aPrime : BigInt })
onceSubtract =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "Subtract"
    , data = Nothing
    , params = []
    , decoder = subtractDecoder
    }


decodeSubtract : String -> Result Error (EventLog { professor : Address, numberz : BigInt, aPrime : BigInt })
decodeSubtract response =
    response
        |> D.decodeString subtractDecoder
        |> Result.mapError (\e -> Error e)


subtractDecoder =
    decode (\professor numberz aPrime -> { professor = professor, numberz = numberz, aPrime = aPrime })
        |> required "professor" D.addressDecoder
        |> required "numberz" D.bigIntDecoder
        |> required "aPrime" D.bigIntDecoder



{- UintArray event -}


subscribeUintArray : ( Address, EventId ) -> Cmd msg
subscribeUintArray =
    Contract.subscribe abi_ "UintArray"


onceUintArray : Contract.Params (EventLog { uintArrayLog : BigInt })
onceUintArray =
    { abi = abi_
    , gasPrice = Just (BI.fromInt 300000000)
    , gas = Just 300000
    , methodName = Just "UintArray"
    , data = Nothing
    , params = []
    , decoder = D.bigIntDecoder
    }


decodeUintArray : String -> Result Error (EventLog { uintArrayLog : BigInt })
decodeUintArray response =
    response
        |> D.decodeString D.bigIntDecoder
        |> Result.mapError (\e -> Error e)



{- Contract Helper Functions -}


encodeContractABI : Constructor -> Task Error Hex
encodeContractABI { constructorInt_, constructorString_ } =
    Contract.encodeContractABI
        { abi = abi_
        , gasPrice = Just (BI.fromInt 300000000)
        , gas = Just 300000
        , methodName = Nothing
        , data = Nothing
        , params = [ E.encodeBigInt, E.string ]
        , decoder = D.hexDecoder
        }


estimateContractGas : Constructor -> Task Error Int
estimateContractGas { constructorInt_, constructorString_ } =
    Contract.estimateContractGas
        { abi = abi_
        , gasPrice = Just (BI.fromInt 300000000)
        , gas = Just 300000
        , methodName = Nothing
        , data = Nothing
        , params = [ E.encodeBigInt, E.string ]
        , decoder = D.hexDecoder
        }


deploy : Address -> Maybe BigInt -> Constructor -> Task Error ContractInfo
deploy from value constructor =
    let
        buildAndDeployTx : Task Error TxId
        buildAndDeployTx =
            estimateContractGas constructor
                |> Task.andThen
                    (\gasCost ->
                        encodeContractABI constructor
                            |> Task.andThen
                                (\data ->
                                    Eth.sendTransaction from
                                        { to = Nothing
                                        , value = value
                                        , gas = gasCost
                                        , data = Just data
                                        , gasPrice = Just 10000000000
                                        , chainId = Nothing
                                        , nonce = Nothing
                                        }
                                )
                    )

        failIfNothing : Error -> Maybe a -> Task Error a
        failIfNothing error maybeVal =
            case maybeVal of
                Nothing ->
                    Task.fail error

                Just a ->
                    Task.succeed a

        waitForTxReceipt : TxId -> Task Error TxReceipt
        waitForTxReceipt txId =
            Eth.getTransactionReceipt txId
                |> Task.andThen (failIfNothing (Error "No Tx Receipt still. Mining error. Network Congestion?"))
                |> Web3.retry { attempts = 30, sleep = 3 }

        returnContractInfo : TxReceipt -> Task Error ContractInfo
        returnContractInfo txReceipt =
            case txReceipt.contractAddress of
                Nothing ->
                    Task.fail (Error "No contract address in Tx Receipt. This error should never happen...")

                Just contractAddress ->
                    Task.succeed { txId = txReceipt.transactionHash, address = contractAddress }
    in
        buildAndDeployTx
            |> Task.andThen waitForTxReceipt
            |> Task.andThen returnContractInfo
