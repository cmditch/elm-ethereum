module Web3.Defaults
    exposing
        ( zeroAddress
        , invalidAddress
        , emptyBlockHash
        , emptyTxHash
        , emptyLogFilter
        )

{-| Default values.
For those withDefault shenanigans.

@docs invalidAddress, zeroAddress, emptyBlockHash, emptyTxHash, emptyLogFilter

-}

import Web3.Internal.Types as Internal
import Web3.Eth.Types exposing (..)


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
