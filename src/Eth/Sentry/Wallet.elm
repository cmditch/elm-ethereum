module Eth.Sentry.Wallet exposing (WalletSentry, default, decoder, decodeToMsg)

{-| Wallet Sentry

@docs WalletSentry, default, decoder, decodeToMsg

-}

import Eth.Decode as Decode
import Eth.Net as Net exposing (NetworkId(..))
import Eth.Types exposing (Address)
import Json.Decode as Decode exposing (Decoder, Value)


{-| -}
type alias WalletSentry =
    { account : Maybe Address
    , networkId : NetworkId
    }


{-| -}
default : WalletSentry
default =
    WalletSentry Nothing (Private 0)


{-| -}
decoder : Decoder WalletSentry
decoder =
    Decode.map2 WalletSentry
        (Decode.field "account" (Decode.maybe Decode.address))
        (Decode.field "networkId" Net.networkIdDecoder)


{-| -}
decodeToMsg : (String -> msg) -> (WalletSentry -> msg) -> Value -> msg
decodeToMsg failMsg successMsg val =
    case Decode.decodeValue decoder val of
        Err error ->
            failMsg (Decode.errorToString error)

        Ok walletSentry ->
            successMsg walletSentry
