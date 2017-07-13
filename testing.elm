module Main exposing (..)

import Dict exposing (Dict)


type Web3Object
    = EthBlock
    | EthBlockNumber
    | Tx
    | TxId
    | Address


web3model : Dict Int Web3Object
web3model =
    Dict.fromList [ ( 1, Address ), ( 2, EthBlockNumber ) ]
