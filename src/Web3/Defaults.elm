module Web3.Defaults
    exposing
        ( zeroAddress
        , blockHash
        , txHash
          --, txParams
          --, logFilter
        )

import Web3.Internal.Types as Internal
import Web3.Eth.Types exposing (..)


zeroAddress : Address
zeroAddress =
    Internal.Address "0000000000000000000000000000000000000000"


blockHash : BlockHash
blockHash =
    Internal.BlockHash "0000000000000000000000000000000000000000000000000000000000000000"


txHash : TxHash
txHash =
    Internal.TxHash "0000000000000000000000000000000000000000000000000000000000000000"
