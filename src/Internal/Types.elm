module Internal.Types exposing (Address(..), BlockHash(..), DebugLogger, Hex(..), IPFSHash(..), TxHash(..), WhisperId(..))


type Address
    = Address String


type TxHash
    = TxHash String


type BlockHash
    = BlockHash String


type WhisperId
    = WhisperId String


type IPFSHash
    = IPFSHash String


type Hex
    = Hex String


type alias DebugLogger a =
    String -> a -> a
