module Eth.Net
    exposing
        ( version
        , clientVersion
        , listening
        , peerCount
        , toId
        , idToInt
        , idToString
        , idDecoder
        , NetworkId(..)
        )

{-| NetworkId and RPC Methods

@docs NetworkId, version, clientVersion, listening, peerCount, toId, idToInt, idToString, idDecoder

-}

import Eth.Types exposing (HttpProvider)
import Internal.Decode as Decode
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
        , decoder = idDecoder
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


{-| Decode a JSON stringy int or JSON int to a NetworkId

    decodeString idDecoder "1"          == Ok Mainnet
    decodeString idDecoder 3            == Ok Ropsten
    decodeString idDecoder "five"       == Err ...

-}
idDecoder : Decoder NetworkId
idDecoder =
    Decode.oneOf
        [ stringyIdDecoder
        , intyIdDecoder
        ]


stringyIdDecoder : Decoder NetworkId
stringyIdDecoder =
    (String.toInt >> Result.map toId)
        |> Decode.resultToDecoder


intyIdDecoder : Decoder NetworkId
intyIdDecoder =
    Decode.int |> Decode.map toId


{-| Convert an int into it's NetworkId
-}
toId : Int -> NetworkId
toId idInt =
    case idInt of
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
            Private idInt


{-| Convert an int into it's NetworkId
-}
idToInt : NetworkId -> Int
idToInt networkId =
    case networkId of
        Mainnet ->
            1

        Expanse ->
            2

        Ropsten ->
            3

        Rinkeby ->
            4

        RskMain ->
            30

        RskTest ->
            31

        Kovan ->
            42

        ETCMain ->
            41

        ETCTest ->
            62

        Private id ->
            id


{-| Get a NetworkId's name
-}
idToString : NetworkId -> String
idToString networkId =
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
