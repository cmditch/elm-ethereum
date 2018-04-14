module Web3.Eth exposing (..)

import Http
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


-- Internal

import Web3.Types exposing (..)
import Web3.Encode as Encode
import Web3.Decode as Decode


-- RPC Calls


call : String -> TxParams a -> Task Http.Error a
call ethNode callData =
    callAtBlock ethNode callData Latest


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


callAtBlock : String -> TxParams a -> BlockId -> Task Http.Error a
callAtBlock ethNode txParams blockId =
    buildRequest
        { url = ethNode
        , method = "eth_call"
        , params = [ Encode.callParams txParams, Encode.blockId blockId ]
        , decoder = txParams.decoder
        }


getTransactionByHash : String -> TxId -> Task Http.Error Tx
getTransactionByHash ethNode (TxId txId) =
    buildRequest
        { url = ethNode
        , method = "eth_getTransactionByHash"
        , params = [ Encode.string txId ]
        , decoder = Decode.tx
        }


getTransactionReceipt : String -> TxId -> Task Http.Error TxReceipt
getTransactionReceipt ethNode (TxId txId) =
    buildRequest
        { url = ethNode
        , method = "eth_getTransactionReceipt"
        , params = [ Encode.string txId ]
        , decoder = Decode.txReceipt
        }


getLogs : String -> LogFilter -> Task Http.Error (List Log)
getLogs ethNode logFilter =
    buildRequest
        { url = "https://mainnet.infura.io/metamask"
        , method = "eth_getLogs"
        , params = [ Encode.logFilter logFilter ]
        , decoder = Decode.list Decode.log
        }



-- JSON RPC


buildRequest : RpcRequest a -> Task Http.Error a
buildRequest { url, method, params, decoder } =
    Http.post url (httpRpcBody method params) (Decode.field "result" decoder)
        |> Http.toTask


rpcBody : Int -> String -> List Value -> Http.Body
rpcBody id method params =
    Encode.rpc id method params
        |> Http.jsonBody


httpRpcBody : String -> List Value -> Http.Body
httpRpcBody =
    rpcBody 1


type alias RpcRequest a =
    { url : String
    , method : String
    , params : List Value
    , decoder : Decoder a
    }
