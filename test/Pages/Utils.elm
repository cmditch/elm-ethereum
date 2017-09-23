module Pages.Utils exposing (..)

import Element exposing (..)
import Config exposing (..)
import Dict exposing (Dict)
import Task exposing (Task)
import BigInt exposing (BigInt)
import Web3.Utils
import Web3.Types exposing (..)
import Element.Attributes exposing (..)


-- import Element.Events exposing (..)
-- import Style exposing (..)
-- import Color
-- import Style.Color as Color
-- import BigInt exposing (BigInt)
-- import Web3
-- import Web3.Eth
-- import Web3.Eth.Contract as Contract
-- import Web3.Eth.Accounts as Accounts
-- import Web3.Eth.Wallet as Wallet
-- import TestContract as TC


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
    [ Task.attempt (RandomHex "randomHex") (Web3.Utils.randomHex 20)
    , Task.attempt (Sha3 "sha3") (Web3.Utils.sha3 "History is not a burden on the memory but an illumination of the soul.")
    , Task.attempt (IsHex "isHex") (Web3.Utils.isHex "0x4f6e20736f6d6520677265617420616e642067")
    , Task.attempt (IsAddress "isAddress") (Web3.Utils.isAddress config.account)
    , Task.attempt (ToChecksumAddress "toChecksumAddress") (Web3.Utils.toChecksumAddress config.account)
    , Task.attempt (CheckAddressChecksum "checkAddressChecksum") (Web3.Utils.checkAddressChecksum config.account)
    , Task.attempt (ToHex "toHex") (Web3.Utils.toHex "The danger is not that a particular class is unfit to govern. Every class is unfit to govern.")
    , Task.attempt (HexToNumberString "hexToNumberString") (Web3.Utils.hexToNumberString (Hex "0x67932"))
    , Task.attempt (HexToNumber "hexToNumber") (Web3.Utils.hexToNumber (Hex "0x67932"))
    , Task.attempt (NumberToHex "numberToHex") (Web3.Utils.numberToHex 424242)
    , Task.attempt (BigIntToHex "bigIntToHex") (Web3.Utils.bigIntToHex (BigInt.fromInt 424242))
    , Task.attempt (HexToUtf8 "hexToUtf8") (Web3.Utils.hexToUtf8 (Hex "0x5361746f736869204e616b616d6f746f"))
    , Task.attempt (Utf8ToHex "utf8ToHex") (Web3.Utils.utf8ToHex "Satoshi Nakamoto")
    , Task.attempt (HexToAscii "hexToAscii") (Web3.Utils.hexToAscii (Hex "0x4f6e20736f6d6520677265617420616e6420676c6f72696f7573206461792074686520706c61696e20666f6c6b73206f6620746865206c616e642077696c6c207265616368207468656972206865617274277320646573697265206174206c6173742c20616e642074686520576869746520486f7573652077696c6c2062652061646f726e6564206279206120646f776e7269676874206d6f726f6e2e202d20482e4c2e204d656e636b656e"))
    , Task.attempt (AsciiToHex "asciiToHex") (Web3.Utils.asciiToHex "'I'm not a driven businessman, but a driven artist. I never think about money. Beautiful things make money.'")
    , Task.attempt (HexToBytes "hexToBytes") (Web3.Utils.hexToBytes (Hex "0x0102030405060708090a0f2aff"))
    , Task.attempt (BytesToHex "bytesToHex") (Web3.Utils.bytesToHex (Bytes [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 42, 255 ]))
    , Task.attempt (ToWei "toWei") (resultToTask <| Web3.Utils.toWei Ether "42")
    , Task.attempt (FromWei "fromWei") (Task.succeed <| Web3.Utils.fromWei Ether ((BigInt.fromString "42000000000000000000") ?= (BigInt.fromInt 42)))
    , Task.attempt (BigIntToWei "bigIntToWei") (Task.succeed <| Web3.Utils.bigIntToWei Ether (BigInt.fromInt 42))
    , Task.attempt (LeftPadHex "leftPadHex") (Task.succeed <| Web3.Utils.leftPadHex (Hex "0x0102030405060708090a0f2aff"))
    , Task.attempt (RightPadHex "rightPadHex") (Task.succeed <| Web3.Utils.rightPadHex (Hex "0x0102030405060708090a0f2aff"))
    ]


viewTest : Test -> Element Styles Variations Msg
viewTest test =
    row TestRow
        [ spacing 20, paddingXY 20 20 ]
        [ column TestPassed [ vary Pass test.passed, vary Fail (not test.passed) ] [ text <| toString test.passed ]
        , column TestName [ paddingXY 20 0 ] [ text test.name ]
        , column TestResponse [ attribute "title" test.response, maxWidth <| percent 70 ] [ text test.response ]
        ]


view : Model -> Element Styles Variations Msg
view model =
    let
        testsTable =
            model.tests
                ?= Dict.empty
                |> Dict.values
                |> List.map viewTest

        titleRow =
            [ row TestTitle [ padding 30, center ] [ text "Web3.Utils" ] ]
    in
        column None [ width fill, scrollbars ] (titleRow ++ testsTable)


type Msg
    = RandomHex String (Result Error Hex)
    | Sha3 String (Result Error Sha3)
    | IsHex String (Result Error Bool)
    | IsAddress String (Result Error Bool)
    | ToChecksumAddress String (Result Error Address)
    | CheckAddressChecksum String (Result Error Bool)
    | ToHex String (Result Error Hex)
    | HexToNumberString String (Result Error String)
    | HexToNumber String (Result Error Int)
    | NumberToHex String (Result Error Hex)
    | BigIntToHex String (Result Error Hex)
    | HexToUtf8 String (Result Error String)
    | Utf8ToHex String (Result Error Hex)
    | HexToAscii String (Result Error String)
    | AsciiToHex String (Result Error Hex)
    | HexToBytes String (Result Error Bytes)
    | BytesToHex String (Result Error Hex)
    | ToWei String (Result Error BigInt)
    | FromWei String (Result Error String)
    | BigIntToWei String (Result Error BigInt)
    | LeftPadHex String (Result Error Hex)
    | RightPadHex String (Result Error Hex)
    | LeftPadHexCustom String (Result Error Hex)
    | RightPadHexCustom String (Result Error Hex)


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    let
        updateTest key val =
            (model.tests ?= Dict.empty) |> (Dict.insert key val >> Just)

        updateModel key funcName result =
            case result of
                Ok val ->
                    { model | tests = updateTest key (Test funcName (Debug.log "ELM UPDATE OK: " <| toString val) True) }

                Err (Error err) ->
                    { model | tests = updateTest key { name = funcName, response = (Debug.log "ELM UPDATE ERR: " <| toString err), passed = False } }
    in
        case msg of
            RandomHex funcName result ->
                updateModel 1 funcName result ! []

            Sha3 funcName result ->
                updateModel 2 funcName result ! []

            IsHex funcName result ->
                updateModel 3 funcName result ! []

            IsAddress funcName result ->
                updateModel 4 funcName result ! []

            ToChecksumAddress funcName result ->
                updateModel 5 funcName result ! []

            CheckAddressChecksum funcName result ->
                updateModel 6 funcName result ! []

            ToHex funcName result ->
                updateModel 7 funcName result ! []

            HexToNumberString funcName result ->
                updateModel 8 funcName result ! []

            HexToNumber funcName result ->
                updateModel 9 funcName result ! []

            NumberToHex funcName result ->
                updateModel 10 funcName result ! []

            BigIntToHex funcName result ->
                updateModel 11 funcName result ! []

            HexToUtf8 funcName result ->
                updateModel 12 funcName result ! []

            Utf8ToHex funcName result ->
                updateModel 13 funcName result ! []

            HexToAscii funcName result ->
                updateModel 14 funcName result ! []

            AsciiToHex funcName result ->
                updateModel 15 funcName result ! []

            HexToBytes funcName result ->
                updateModel 16 funcName result ! []

            BytesToHex funcName result ->
                updateModel 17 funcName result ! []

            ToWei funcName result ->
                updateModel 18 funcName result ! []

            FromWei funcName result ->
                updateModel 19 funcName result ! []

            BigIntToWei funcName result ->
                updateModel 20 funcName result ! []

            LeftPadHex funcName result ->
                updateModel 21 funcName result ! []

            RightPadHex funcName result ->
                updateModel 22 funcName result ! []

            LeftPadHexCustom funcName result ->
                updateModel 23 funcName result ! []

            RightPadHexCustom funcName result ->
                updateModel 24 funcName result ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []
