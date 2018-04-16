module Web3.Internal.Types
    exposing
        ( Address(..)
        , TxHash(..)
        , BlockHash(..)
        , Hex(..)
        , IPFSHash(..)
        )


type Address
    = Address String


type TxHash
    = TxHash String


type BlockHash
    = BlockHash String



-- vVv    Keep in Library?   vVv


type Hex
    = Hex String


type IPFSHash
    = IPFSHash Base58


type Base58
    = Base58 String
