module Web3.Defaults
    exposing
        ( zeroAddress
        , blockHash
          --, txParams
          --, logFilter
        )

import Web3.Internal.Types as Internal
import Web3.Eth.Types exposing (Address, BlockHash)


zeroAddress : Address
zeroAddress =
    Internal.Address "0000000000000000000000000000000000000000"


blockHash : BlockHash
blockHash =
    Internal.BlockHash "0000000000000000000000000000000000000000000000000000000000000000"
