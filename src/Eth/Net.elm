module Eth.Net
    exposing
        ( version
        , clientVersion
        , listening
        , peerCount
        , networkId
        , name
        , networkIdDecoder
        , NetworkId(..)
        )

{-| NetworkId and RPC Methods

@docs version, clientVersion, listening, peerCount, networkId, name, networkIdDecoder, NetworkId

-}

import Eth.Types exposing (HttpProvider)
import Eth.Decode as Decode
import Eth.RPC as RPC
import Http
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


{-| -}
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


{-| Get the current network id.

    Ok Mainnet

-}
version : HttpProvider -> Task Http.Error NetworkId
version ethNode =
    RPC.toTask
        { url = ethNode
        , method = "net_version"
        , params = []
        , decoder = networkIdDecoder
        }


{-| Get the current client version.

    Ok "Mist/v0.9.3/darwin/go1.4.1"

-}
clientVersion : HttpProvider -> Task Http.Error String
clientVersion ethNode =
    RPC.toTask
        { url = ethNode
        , method = "web3_clientVersion"
        , params = []
        , decoder = Decode.string
        }


{-| Returns true if the node is actively listening for network connections.
-}
listening : HttpProvider -> Task Http.Error Bool
listening ethNode =
    RPC.toTask
        { url = ethNode
        , method = "net_listening"
        , params = []
        , decoder = Decode.bool
        }


{-| Get the number of peers currently connected to the client.
-}
peerCount : HttpProvider -> Task Http.Error Int
peerCount ethNode =
    RPC.toTask
        { url = ethNode
        , method = "net_peerCount"
        , params = []
        , decoder = Decode.stringInt
        }


{-| Decode a stringy int into it's NetworkId
-}
networkIdDecoder : Decoder NetworkId
networkIdDecoder =
    (String.toInt >> Result.map networkId)
        |> Decode.resultToDecoder


{-| Convert an int into it's NetworkId
-}
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


{-| Get a NetworkId's name
-}
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

        Private num ->
            "Private Chain: " ++ toString num
