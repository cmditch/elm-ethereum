module Web3.Types
    exposing
        ( HttpProvider
        , FilterId
        , Hex
        , IPFSHash
        )

{-| Web3 Types

@docs HttpProvider, FilterId, Hex, IPFSHash

-}

import Web3.Internal.Types as Internal


{-| -}
type alias HttpProvider =
    String


{-| -}
type alias FilterId =
    String


{-| -}
type alias Hex =
    Internal.Hex


{-| -}
type alias IPFSHash =
    Internal.IPFSHash
