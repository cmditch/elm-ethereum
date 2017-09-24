module Pages.Wallet exposing (..)

import Element exposing (..)
import Config exposing (..)
import Task exposing (Task)
import Web3.Types exposing (..)
import Element.Attributes exposing (..)
import Web3.Eth.Accounts as Accounts
import Web3.Eth.Wallet as Wallet
import Element.Events exposing (..)


init : Model
init =
    { newAccount = Nothing
    , error = Nothing
    }


type alias Model =
    { newAccount : Maybe Account
    , error : Maybe Error
    }


initCreateAccount : Cmd Msg
initCreateAccount =
    Task.attempt Create Accounts.create


viewTest : Test -> Element Styles Variations Msg
viewTest test =
    row TestRow
        [ spacing 20, paddingXY 20 20 ]
        [ column TestPassed [ vary Pass test.passed, vary Fail (not test.passed) ] [ text <| toString test.passed ]
        , column TestName [ paddingXY 20 0 ] [ text test.name ]
        , column TestResponse [ attribute "title" test.response, maxWidth <| percent 70 ] [ text test.response ]
        ]


viewAccountTests : Model -> List (Element Styles Variations Msg)
viewAccountTests model =
    let
        createAccount =
            row TestRow
                [ spacing 20, paddingXY 20 20 ]
                [ column None [] [ button None [ onClick InitCreate ] (text "Create") ]
                ]

        viewAccount account =
            row TestResponse
                [ verticalCenter ]
                [ column None
                    [ spacing 10 ]
                    [ text <| toString account.address, text <| toString account.privateKey ]
                ]

        viewNewAccount account =
            row TestRow
                [ spacing 20, paddingXY 20 13, xScrollbar ]
                [ column None
                    [ verticalCenter, spacing 15 ]
                    [ button None [ onClick InitCreate ] (text "Create Account") ]
                , viewAccount account
                ]

        viewTestRow name elements =
            row TestRow
                [ spacing 20, paddingXY 20 0 ]
                [ column TestName [ verticalCenter, minWidth (px 180), paddingXY 0 15 ] [ text name ]
                , column VerticalBar [] []
                , row TestResponse [ verticalCenter, paddingXY 0 10, xScrollbar ] [ column None [ spacing 5 ] elements ]
                ]
    in
        case model.newAccount of
            Nothing ->
                [ createAccount ]

            Just account ->
                [ viewNewAccount account ]


titleRow : Model -> List (Element Styles Variations Msg)
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
            [ text "Web3.Eth.Wallet"
            , column None [ alignRight ] [ error ]
            ]
        ]


view : Model -> Element Styles Variations Msg
view model =
    column None
        [ width fill, scrollbars ]
        (titleRow model ++ viewAccountTests model)


type Msg
    = InitCreate
    | Create (Result Error Account)


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        InitCreate ->
            model ! [ Task.attempt Create Accounts.create ]

        Create result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok account ->
                    { model | newAccount = Just account }
                        ! []
