module Web3.Defaults
    exposing
        ( zeroAddress
          --, txParams
          --, logFilter
        )

import Web3.Internal.Types as Internal
import Web3.Types exposing (Address)


zeroAddress : Address
zeroAddress =
    Internal.Address "0000000000000000000000000000000000000000"
