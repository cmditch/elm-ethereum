module Notes exposing (andPrepend, callHelper, newWidget, newWidget2)

import Abi.Encode as AbiEncode
import BigInt exposing (BigInt)
import Eth.Types exposing (Address, Call, Hex, IPFSHash)
import Json.Decode as Decode
import Result.Extra


{-| TO-DO

  - Remove dependency on web3.js, and work with common provider format to communicate with RPC

  - Rework Sentry.Event
      - initHttp, initWebsocket
      - HTTP will have to handle filter installation, clearing, polling.
      - withDebug, takes Debug.log from user

  - Rework Abi.Encode
      - Support various uint, int, and byte sizes
      - Fail upon overflows

  - Use more generic error type
      - Helps caputure cases like uint overflows above

  - Update elm-ethereum-generator
      - Better parser
      - Dynamic types

  - Make 0.19 compatible
      - Remove Debug.logs
      - Replace any flip, (%), etc.
      - Fix var shadowing

  - Allow parsing events from TxReceipts

  - Create Encode/Decode modules, make all that private stuff public.

  - Change all BigInt.fromString to BigInt.fromHexString where necessary.

-}



-- newWidget : Address -> BigInt -> BigInt -> Address -> Call ()


newWidget contractAddress size_ cost_ owner_ =
    (AbiEncode.uint 256 size_ :: AbiEncode.uint 256 cost_ :: AbiEncode.address owner_ :: [])
        |> Result.Extra.combine
        |> Result.map (AbiEncode.functionCall "newWidget(uint256,uint256,address)")
        |> Result.map (callHelper contractAddress (Decode.succeed ()))


newWidget2 : Address -> BigInt -> BigInt -> Address -> Result String (Call ())
newWidget2 contractAddress size_ cost_ owner_ =
    Result.Extra.singleton []
        |> andPrepend (AbiEncode.uint 256 size_)
        |> andPrepend (AbiEncode.uint 256 cost_)
        |> andPrepend (AbiEncode.address owner_)
        |> Result.map (AbiEncode.functionCall "newWidget(uint256,uint256,address)")
        |> Result.map (callHelper contractAddress (Decode.succeed ()))


andPrepend : Result e a -> Result e (List a) -> Result e (List a)
andPrepend =
    Result.map2 (::)


callHelper : Address -> Decode.Decoder a -> Hex -> Call a
callHelper contractAddress decoder data =
    { to = Just contractAddress
    , from = Nothing
    , gas = Nothing
    , gasPrice = Nothing
    , value = Nothing
    , data = Just data
    , nonce = Nothing
    , decoder = decoder
    }
