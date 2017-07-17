module Web3.Eth.Contract
    exposing
        ( call
        , sendTransaction
        )

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Address, CallData, SendData)
import Task exposing (Task)


-- Still needs implemenation


call : CallData -> Task Error a
call data =
    Native.Web3.contractCall data


sendTransaction : SendData -> Task Error a
sendTransaction data =
    Native.Web3.contractSend data
