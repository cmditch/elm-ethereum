module Pages.Accounts exposing (..)

import Element exposing (..)
import Config exposing (..)
import Dict exposing (Dict)
import Task exposing (Task)
import Web3.Types exposing (..)
import Element.Attributes exposing (..)
import Web3.Eth.Accounts as Accounts
import Element.Events exposing (..)
import Element.Input as Input exposing (Text)


-- import BigInt exposing (BigInt)
-- import Web3.Utils
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
    , entropy = ""
    , signedMsg = Nothing
    , signedTx = Nothing
    , tests = Nothing
    , error = Nothing
    }


type alias Model =
    { newAccount : Maybe Account
    , entropy : String
    , signedMsg : Maybe SignedMsg
    , signedTx : Maybe SignedTx
    , tests : Maybe (Dict.Dict Int Test)
    , error : Maybe Error
    }


initCreateAccount : Cmd Msg
initCreateAccount =
    Task.attempt Create Accounts.create


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


viewNewAccount : Model -> List (Element Styles Variations Msg)
viewNewAccount model =
    let
        entropyTextfieldConfig =
            { onChange = Entropy
            , value = model.entropy
            , label = Input.placeholder { text = "Define Entropy", label = Input.hiddenLabel "Paste entropy" }
            , options = []
            }

        viewNewAccount account =
            row TestRow
                [ spacing 20, paddingXY 20 13 ]
                [ column None
                    [ verticalCenter, spacing 15 ]
                    [ button None [ onClick InitCreate ] (text "Create Account")
                    , row None
                        [ spacing 15 ]
                        [ Input.text TextField [] entropyTextfieldConfig
                        , button None [ onClick InitCreateWithEntropy ] (text "Create w/ Entropy")
                        ]
                    ]
                , row TestResponse [] [ column None [ spacing 10 ] [ text <| toString account.address, text <| toString account.privateKey ] ]
                ]

        signMessage =
            case model.signedMsg of
                Nothing ->
                    row TestRow [] []

                Just { message, messageHash, r, s, v, signature } ->
                    row TestRow
                        [ spacing 20, paddingXY 20 13 ]
                        [ column None [ verticalCenter ] [ button None [] (text "Sign Msg") ]
                        , row TestResponse
                            []
                            [ column None
                                []
                                [ text ("Message: " ++ (toString message))
                                , text ("MessageHash: " ++ (toString messageHash))
                                , text ("r: " ++ (toString r))
                                , text ("s: " ++ (toString s))
                                , text ("v: " ++ (toString v))
                                , text ("signature: " ++ (toString signature))
                                ]
                            ]
                        ]

        signTransaction =
            case model.signedTx of
                Nothing ->
                    row TestRow [] []

                Just { message, messageHash, r, s, v, rawTransaction } ->
                    row TestRow
                        [ spacing 20, paddingXY 20 13 ]
                        [ column None [ verticalCenter ] [ button None [] (text "Sign Tx") ]
                        , row TestResponse
                            []
                            [ column None
                                []
                                [ text ("Message: " ++ (toString message))
                                , text ("MessageHash: " ++ (toString messageHash))
                                , text ("r: " ++ (toString r))
                                , text ("s: " ++ (toString s))
                                , text ("v: " ++ (toString v))
                                , text ("signature: " ++ (toString rawTransaction))
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
                [ createAccount ]

            Just account ->
                [ viewNewAccount account, signMessage, signTransaction ]


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
            [ text "Web3.Eth.Accounts"
            , column None [ alignRight ] [ error ]
            ]
        ]


view : Model -> Element Styles Variations Msg
view model =
    column None
        [ width fill, scrollbars ]
        (titleRow model ++ viewNewAccount model)


type Msg
    = InitCreate
    | Entropy String
    | InitCreateWithEntropy
    | Create (Result Error Account)
    | SignMsg (Result Error SignedMsg)
    | SignTx (Result Error SignedTx)


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
            InitCreate ->
                model ! [ Task.attempt Create Accounts.create ]

            Entropy entropyString ->
                { model | entropy = entropyString } ! []

            InitCreateWithEntropy ->
                model ! [ Task.attempt Create <| Accounts.createWithEntropy model.entropy ]

            Create result ->
                case result of
                    Err err ->
                        { model | error = Just err } ! []

                    Ok account ->
                        { model | newAccount = Just account }
                            ! [ Task.attempt SignMsg <| Accounts.sign account "This is a test message"
                              , Task.attempt SignTx <| Accounts.signTransaction account config.txParams
                              ]

            SignMsg result ->
                case result of
                    Err err ->
                        { model | error = Just err } ! []

                    Ok sig ->
                        { model | signedMsg = Just sig } ! []

            SignTx result ->
                case result of
                    Err err ->
                        { model | error = Just err } ! []

                    Ok sig ->
                        { model | signedTx = Just sig } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []
