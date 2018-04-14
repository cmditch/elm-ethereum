module Web3.Internal.Types
    exposing
        ( Hex(..)
        , Address(..)
        , IPFSHash(..)
        , TxHash(..)
        )


type Hex
    = Hex String


type Base58
    = Base58 String


type Address
    = Address String


type IPFSHash
    = IPFSHash Base58


type TxHash
    = TxHash String
