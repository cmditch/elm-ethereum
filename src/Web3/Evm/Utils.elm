module Web3.Evm.Utils exposing (..)


take64 : String -> String
take64 =
    String.left 64


drop64 : String -> String
drop64 =
    String.dropLeft 64


leftPad : String -> String
leftPad data =
    String.padLeft 64 '0' data
