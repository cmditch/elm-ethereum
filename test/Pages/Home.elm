module Pages.Home exposing (..)

import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Style exposing (..)
import Color
import Style.Color as Color
import Config exposing (..)
import Task exposing (Task)
import Web3.Types exposing (..)
import Web3.Eth
import Web3.Utils


init : Model
init =
    ""


type alias Model =
    String


testCommands : Config -> List (Cmd Msg)
testCommands config =
    [ Task.attempt (Sha3 "web3.utils.sha3") (Web3.Utils.sha3 "History is not a burden on the memory but an illumination of the soul.")
    , Task.attempt (ToHex "web3.utils.toHex") (Web3.Utils.toHex "The danger is not that a particular class is unfit to govern. Every class is unfit to govern.")
    , Task.attempt (HexToAscii "web3.utils.hexToAscii") (Web3.Utils.hexToAscii (Hex "0x4f6e20736f6d6520677265617420616e6420676c6f72696f7573206461792074686520706c61696e20666f6c6b73206f6620746865206c616e642077696c6c207265616368207468656972206865617274277320646573697265206174206c6173742c20616e642074686520576869746520486f7573652077696c6c2062652061646f726e6564206279206120646f776e7269676874206d6f726f6e2e202d20482e4c2e204d656e636b656e"))
    , Task.attempt (AsciiToHex "web3.utils.asciiToHex") (Web3.Utils.asciiToHex "'I'm not a driven businessman, but a driven artist. I never think about money. Beautiful things make money.'")
    , Task.attempt (HexToNumber "web3.utils.hexToNumber") (Web3.Utils.hexToNumber (Hex "0x67932"))
    , Task.attempt (NumberToHex "web3.utils.numberToHex") (Web3.Utils.numberToHex 424242)
    , Task.attempt (IsAddress "web3.utils.isAddress") (Web3.Utils.isAddress config.account)
    , Task.attempt (CheckAddressChecksum "web3.utils.checkAddressChecksum") (Web3.Utils.checkAddressChecksum config.account)
    , Task.attempt (ToChecksumAddress "web3.utils.toChecksumAddress") (Web3.Utils.toChecksumAddress config.account)
    ]


view : Model -> Element Styles variation msg
view model =
    column None [] []


type Msg
    = Sha3 String (Result Error Sha3)
    | ToHex String (Result Error Hex)
    | HexToAscii String (Result Error String)
    | AsciiToHex String (Result Error Hex)
    | HexToNumber String (Result Error Int)
    | NumberToHex String (Result Error Hex)
    | IsAddress String (Result Error Bool)
    | CheckAddressChecksum String (Result Error Bool)
    | ToChecksumAddress String (Result Error Address)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []
