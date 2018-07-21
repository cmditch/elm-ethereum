module Data.Chain exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Eth.Types exposing (Address)
import Eth.Utils as EthUtils
import Eth.Net as EthNet exposing (NetworkId(..))
import Eth.Decode as EthDecode
import Eth.Types exposing (HttpProvider, WebsocketProvider)


widgetFactory : Address
widgetFactory =
    EthUtils.unsafeToAddress "0x36dde2719a01ec108304d830d537aec3fb7c1bbf"


metamaskAccountDecoder : Decoder (Maybe Address)
metamaskAccountDecoder =
    Decode.maybe EthDecode.address


networkIdDecoder : Decoder (Maybe NetworkId)
networkIdDecoder =
    Decode.maybe EthNet.networkIdDecoder


type alias NodePath =
    { http : HttpProvider
    , ws : WebsocketProvider
    }


nodePath : NetworkId -> NodePath
nodePath networkId =
    case networkId of
        Mainnet ->
            NodePath "https://mainnet.infura.io/" "wss://mainnet.infura.io/ws"

        Ropsten ->
            NodePath "https://ropsten.infura.io/" "wss://ropsten.infura.io/ws"

        Rinkeby ->
            NodePath "https://rinkeby.infura.io/" "wss://rinkeby.infura.io/ws"

        _ ->
            NodePath "UnknownEthNetwork" "UnknownEthNetwork"
