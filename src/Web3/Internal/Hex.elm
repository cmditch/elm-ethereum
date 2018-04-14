module Web3.Internal.Hex exposing (..)


type Base16
    = Base16 String


type Base58
    = Base58 String



-- Constructors
-- Needs character validation, oneOf [1234567890abcdef]
-- and removal of 0x


toBase16 : String -> Result String Base16
toBase16 =
    Base16 >> Ok


toBase58 : String -> Result String Base58
toBase58 =
    Base58 >> Ok



-- Deconstructors


base16ToString : Base16 -> String
base16ToString (Base16 hex) =
    hex


base58ToString : Base58 -> String
base58ToString (Base58 hex) =
    hex



-- Length Checks


base16Length : Base16 -> Int
base16Length (Base16 str) =
    String.length str


base58Length : Base58 -> Int
base58Length (Base58 str) =
    String.length str
