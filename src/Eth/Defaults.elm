module Eth.Defaults exposing (invalidAddress, zeroAddress, emptyBlockHash, emptyTxHash, emptyLogFilter)

{-| Default values.
For those withDefault shenanigans.

@docs invalidAddress, zeroAddress, emptyBlockHash, emptyTxHash, emptyLogFilter

-}

import Eth.Types exposing (..)
import Internal.Types as Internal


{-| -}
invalidAddress : Address
invalidAddress =
    Internal.Address "invalid address to break things"


{-| Danger Will Robinson, why are you using this?
Only to burn things should it be used.
-}
zeroAddress : Address
zeroAddress =
    Internal.Address "0000000000000000000000000000000000000000"


{-| -}
emptyBlockHash : BlockHash
emptyBlockHash =
    Internal.BlockHash "0000000000000000000000000000000000000000000000000000000000000000"


{-| -}
emptyTxHash : TxHash
emptyTxHash =
    Internal.TxHash "0000000000000000000000000000000000000000000000000000000000000000"


{-| -}
emptyLogFilter : LogFilter
emptyLogFilter =
    { fromBlock = LatestBlock
    , toBlock = LatestBlock
    , address = zeroAddress
    , topics = []
    }
