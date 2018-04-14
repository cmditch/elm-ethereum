module Web3.Test exposing (..)

import Web3.Types exposing (Address, toAddress)


a =
    toAddress "0x123123123123"


b : Address -> Int
b address =
    2
