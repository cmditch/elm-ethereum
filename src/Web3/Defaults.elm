module Web3.Defaults
    exposing
        ( zeroAddress
        , invalidAddress
        , emptyBlockHash
        , emptyTxHash
        , emptyLogFilter
          --, txParams
          --, logFilter
        )

import Web3.Internal.Types as Internal
import Web3.Eth.Types exposing (..)


zeroAddress : Address
zeroAddress =
    Internal.Address "0000000000000000000000000000000000000000"


invalidAddress : Address
invalidAddress =
    Internal.Address "invalid address to break things"


emptyBlockHash : BlockHash
emptyBlockHash =
    Internal.BlockHash "0000000000000000000000000000000000000000000000000000000000000000"


emptyTxHash : TxHash
emptyTxHash =
    Internal.TxHash "0000000000000000000000000000000000000000000000000000000000000000"


emptyLogFilter : LogFilter
emptyLogFilter =
    { fromBlock = LatestBlock
    , toBlock = LatestBlock
    , address = zeroAddress
    , topics = []
    }
