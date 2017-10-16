module Web3.Defaults exposing (..)

import Web3.Types exposing (..)


defaultTxParams : TxParams
defaultTxParams =
    { to = Nothing
    , value = Nothing
    , data = Nothing
    , gas = 21000
    , gasPrice = Just 8000000000
    , nonce = Nothing
    , chainId = Just 1
    }


defaultFilterParams : FilterParams
defaultFilterParams =
    { fromBlock = Nothing
    , toBlock = Nothing
    , address = Nothing
    , topics = Nothing
    }
