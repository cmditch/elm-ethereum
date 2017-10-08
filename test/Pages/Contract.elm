module Pages.Contract exposing (..)

import Element exposing (..)
import Config exposing (..)
import Task exposing (Task)
import Dict exposing (Dict)
import BigInt exposing (BigInt)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Web3.Types exposing (..)
import Web3.Eth.Contract as Contract
import TestContract as TC


init : Model
init =
    { tests = Nothing
    , error = Nothing
    }


type alias Model =
    { tests : Maybe (Dict Int Test)
    , error : Maybe Error
    }


testCommands : Config -> List (Cmd Msg)
testCommands config =
    let
        bigBigNumber =
            BigInt.fromInt 1241241241
                |> BigInt.mul (BigInt.fromInt 1241241241)
    in
        [ Task.attempt (ReturnsOneNamed "returnsOneNamed") (Contract.call config.contract <| TC.returnsOneNamed (BigInt.fromInt 12) (BigInt.fromInt 11))
        , Task.attempt (ReturnsOneUnnamed "returnsOneUnnamed") (Contract.call config.contract <| TC.returnsOneUnnamed (BigInt.fromInt 30) (BigInt.fromInt 12))
        , Task.attempt (ReturnsTwoNamed "returnsTwoNamed") (Contract.call config.contract <| TC.returnsTwoNamed (BigInt.fromInt 400) (BigInt.fromInt 20))
        , Task.attempt (ReturnsTwoUnnamed "returnsTwoUnnamed") (Contract.call config.contract <| TC.returnsTwoUnnamed bigBigNumber bigBigNumber)
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
            [ row TestTitle
                [ padding 30, center ]
                [ text "Web3.Eth.Contract" ]
            ]

        testButton =
            [ row TestRow
                [ spacing 20, paddingXY 20 20 ]
                [ button None [ onClick InitTests ] (text "Start Tests") ]
            ]
    in
        column None
            [ width fill, scrollbars ]
            (titleRow ++ testButton ++ testsTable)


type Msg
    = InitTests
    | ReturnsOneNamed String (Result Error BigInt)
    | ReturnsOneUnnamed String (Result Error BigInt)
    | ReturnsTwoNamed String (Result Error { someUint : BigInt, someString : String })
    | ReturnsTwoUnnamed String (Result Error { v0 : String, v1 : String })


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
            InitTests ->
                model ! testCommands config

            ReturnsOneNamed funcName result ->
                updateModel 10 funcName result ! []

            ReturnsOneUnnamed funcName result ->
                updateModel 20 funcName result ! []

            ReturnsTwoNamed funcName result ->
                updateModel 30 funcName result ! []

            ReturnsTwoUnnamed funcName result ->
                updateModel 40 funcName result ! []
