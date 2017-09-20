module Pages.Utils exposing (..)

import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Style exposing (..)
import Color
import Style.Color as Color
import Dict exposing (Dict)
import Task exposing (Task)
import BigInt exposing (BigInt)
import Web3
import Web3.Types exposing (..)
import Web3.Eth
import Web3.Utils
import Web3.Eth.Contract as Contract
import Web3.Eth.Accounts as Accounts
import Web3.Eth.Wallet as Wallet
import TestContract as TC
import Config exposing (..)


init : Model
init =
    { tests = Nothing
    , error = Nothing
    }


type alias Model =
    { tests : Maybe (Dict.Dict Int Test)
    , error : Maybe Error
    }


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


view : Model -> Element Styles variation Msg
view model =
    let
        viewTest test =
            row None [] [ text ("Function: " ++ test.name), text ("Result: " ++ test.result), text ("  " ++ (toString test.passed)) ]

        testsTable =
            model.tests
                ?= Dict.empty
                |> Dict.values
                |> List.map viewTest
    in
        column None [] testsTable


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


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    let
        updateTest key val =
            (model.tests ?= Dict.empty) |> (Dict.insert key val >> Just)

        updateModel key funcName result =
            case result of
                Ok val ->
                    { model | tests = updateTest key (Test funcName (Debug.log "ELM UPDATE OK: " <| toString val) True) }

                Err error ->
                    case error of
                        Error err ->
                            { model | tests = updateTest key (Test funcName (Debug.log "ELM UPDATE ERR: " <| toString err) False) }

                        BadPayload err ->
                            { model | tests = updateTest key (Test funcName (Debug.log "ELM UPDATE ERR: " <| toString err) False) }

                        NoWallet ->
                            { model | tests = updateTest key (Test funcName "ELM UPDATE ERR" False) }
    in
        case msg of
            Sha3 funcName result ->
                updateModel 1 funcName result ! []

            ToHex funcName result ->
                updateModel 2 funcName result ! []

            HexToAscii funcName result ->
                updateModel 3 funcName result ! []

            AsciiToHex funcName result ->
                updateModel 4 funcName result ! []

            HexToNumber funcName result ->
                updateModel 5 funcName result ! []

            NumberToHex funcName result ->
                updateModel 6 funcName result ! []

            IsAddress funcName result ->
                updateModel 7 funcName result ! []

            CheckAddressChecksum funcName result ->
                updateModel 8 funcName result ! []

            ToChecksumAddress funcName result ->
                updateModel 9 funcName result ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []
