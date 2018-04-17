module Web3.Net
    exposing
        ( netVersion
        , netListening
        , netPeerCount
        , networkId
        , name
        , networkIdDecoder
        , NetworkId(..)
        )

import Json.Decode as Decode exposing (Decoder)
import Http
import Task exposing (Task)
import Web3.Types exposing (HttpProvider)
import Web3.Decode as Decode
import Web3.RPC as RPC


type NetworkId
    = Mainnet
    | Expanse
    | Ropsten
    | Rinkeby
    | RskMain
    | RskTest
    | Kovan
    | ETCMain
    | ETCTest
    | Private Int


netVersion : HttpProvider -> Task Http.Error NetworkId
netVersion ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "net_version"
        , params = []
        , decoder = networkIdDecoder
        }


netListening : HttpProvider -> Task Http.Error Bool
netListening ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "net_listening"
        , params = []
        , decoder = Decode.bool
        }


netPeerCount : HttpProvider -> Task Http.Error Int
netPeerCount ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "net_peerCount"
        , params = []
        , decoder = Decode.stringInt
        }


networkIdDecoder : Decoder NetworkId
networkIdDecoder =
    (String.toInt >> Result.map networkId)
        |> Decode.resultToDecoder


networkId : Int -> NetworkId
networkId networkId =
    case networkId of
        1 ->
            Mainnet

        2 ->
            Expanse

        3 ->
            Ropsten

        4 ->
            Rinkeby

        30 ->
            RskMain

        31 ->
            RskTest

        42 ->
            Kovan

        41 ->
            ETCMain

        62 ->
            ETCTest

        _ ->
            Private networkId


name : NetworkId -> String
name networkId =
    case networkId of
        Mainnet ->
            "Mainnet"

        Expanse ->
            "Expanse"

        Ropsten ->
            "Ropsten"

        Rinkeby ->
            "Rinkeby"

        RskMain ->
            "Rootstock"

        RskTest ->
            "Rootstock Test"

        Kovan ->
            "Kovan"

        ETCMain ->
            "ETC Mainnet"

        ETCTest ->
            "ETC Testnet"

        Private networkId ->
            "Private Chain"
