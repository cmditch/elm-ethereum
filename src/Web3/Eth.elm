module Web3.Eth exposing (..)

import Http
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)
import Web3.Types exposing (..)
import Web3.Eth.Encode as Encode
import Web3.Eth.Decode as Decode
import Web3.RPC as RPC


-- ETH


call : HttpProvider -> TxParams a -> Task Http.Error a
call ethNode callData =
    callAtBlock ethNode callData Latest


callAtBlock : HttpProvider -> TxParams a -> BlockId -> Task Http.Error a
callAtBlock ethNode txParams blockId =
    RPC.buildRequest
        { url = ethNode
        , method = "eth_call"
        , params = [ Encode.callParams txParams, Encode.blockId blockId ]
        , decoder = txParams.decoder
        }


send : TxParams a -> Send
send { to, from, gas, gasPrice, value, data, nonce } =
    { to = to
    , from = from
    , gas = gas
    , gasPrice = gasPrice
    , value = value
    , data = data
    , nonce = nonce
    }


getTransactionByHash : HttpProvider -> TxHash -> Task Http.Error Tx
getTransactionByHash ethNode txHash =
    RPC.buildRequest
        { url = ethNode
        , method = "eth_getTransactionByHash"
        , params = [ Encode.txHash txHash ]
        , decoder = Decode.tx
        }


getTransactionReceipt : HttpProvider -> TxHash -> Task Http.Error TxReceipt
getTransactionReceipt ethNode txHash =
    RPC.buildRequest
        { url = ethNode
        , method = "eth_getTransactionReceipt"
        , params = [ Encode.txHash txHash ]
        , decoder = Decode.txReceipt
        }


getLogs : HttpProvider -> LogFilter -> Task Http.Error (List Log)
getLogs ethNode logFilter =
    RPC.buildRequest
        { url = ethNode
        , method = "eth_getLogs"
        , params = [ Encode.logFilter logFilter ]
        , decoder = Decode.list Decode.log
        }



-- WEB3


clientVersion : HttpProvider -> Task Http.Error String
clientVersion ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "web3_clientVersion"
        , params = []
        , decoder = Decode.string
        }



-- NET


netVersion : HttpProvider -> Task Http.Error NetworkId
netVersion ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "net_version"
        , params = []
        , decoder = Decode.netVersion
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
        , decoder = Decode.netPeerCount
        }


protocolVersion : HttpProvider -> Task Http.Error Int
protocolVersion ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "eth_protocolVersion"
        , params = []
        , decoder = Decode.stringyInt
        }


syncing : HttpProvider -> Task Http.Error Int
syncing ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "eth_syncing"
        , params = []
        , decoder = Decode.ethSyncing
        }



--  : HttpProvider ->   -> Task Http.Error
--  ethNode   =
--     RPC.buildRequest
--         { url = ethNode
--         , method = ""
--         , params = [  ]
--         , decoder =
--         }
--  : HttpProvider ->   -> Task Http.Error
--  ethNode   =
--     RPC.buildRequest
--         { url = ethNode
--         , method = ""
--         , params = [  ]
--         , decoder =
--         }
