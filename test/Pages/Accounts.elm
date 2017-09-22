module Pages.Accounts exposing (..)

import Element exposing (..)
import Config exposing (..)
import Dict exposing (Dict)
import Task exposing (Task)
import BigInt exposing (BigInt)
import Web3.Utils
import Web3.Types exposing (..)
import Element.Attributes exposing (..)
import Web3.Eth.Accounts as Accounts
import Element.Events exposing (..)


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
    { newAccount = Nothing
    , tests = Nothing
    , error = Nothing
    }


type alias Model =
    { newAccount : Maybe Account
    , tests : Maybe (Dict.Dict Int Test)
    , error : Maybe Error
    }


testCommands : Config -> List (Cmd Msg)
testCommands config =
    []


viewTest : Test -> Element Styles Variations Msg
viewTest test =
    row TestRow
        [ spacing 20, paddingXY 20 20 ]
        [ column TestPassed [ vary Pass test.passed, vary Fail (not test.passed) ] [ text <| toString test.passed ]
        , column TestName [ paddingXY 20 0 ] [ text test.name ]
        , column TestResponse [ attribute "title" test.response, maxWidth <| percent 70 ] [ text test.response ]
        ]


viewNewAccount : Model -> Element Styles Variations Msg
viewNewAccount model =
    let
        viewAccount account =
            row TestRow
                [ spacing 20, paddingXY 20 13 ]
                [ column None [ verticalCenter ] [ button None [ onClick InitCreate ] (text "Create") ]
                , row TestResponse
                    []
                    [ column None
                        [ spacing 10 ]
                        [ text <| toString account.address
                        , text <| toString account.privateKey
                        ]
                    ]
                ]

        createAccount =
            row TestRow
                [ spacing 20, paddingXY 20 20 ]
                [ column None [] [ button None [ onClick InitCreate ] (text "Create") ]
                ]
    in
        case model.newAccount of
            Nothing ->
                createAccount

            Just account ->
                viewAccount account


titleRow model =
    let
        error =
            case model.error of
                Just error ->
                    text <| toString error

                Nothing ->
                    text ""
    in
        [ row TestTitle
            [ padding 30, center ]
            [ text "Web3.Eth.Accounts"
            , column None [ alignRight ] [ error ]
            ]
        ]



-- manualTests : Element Styles Variations Msg
-- manualTests =


view : Model -> Element Styles Variations Msg
view model =
    let
        testsTable =
            model.tests
                ?= Dict.empty
                |> Dict.values
                |> List.map viewTest
    in
        column None
            [ width fill, scrollbars ]
            (titleRow model ++ [ viewNewAccount model ] ++ testsTable)


type Msg
    = InitCreate
    | Create (Result Error Account)


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
                            { model | tests = updateTest key { name = funcName, response = (Debug.log "ELM UPDATE ERR: " <| toString err), passed = False } }

                        BadPayload err ->
                            { model | tests = updateTest key { name = funcName, response = (Debug.log "ELM UPDATE ERR: " <| toString err), passed = False } }

                        NoWallet ->
                            { model | tests = updateTest key { name = funcName, response = (Debug.log "ELM UPDATE ERR" "NO WALLET"), passed = False } }
    in
        case msg of
            InitCreate ->
                model ! [ Task.attempt Create Accounts.create ]

            Create result ->
                case result of
                    Err err ->
                        { model | error = Just err } ! []

                    Ok account ->
                        { model | newAccount = Just account } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []
