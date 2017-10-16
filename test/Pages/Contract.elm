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
    , returnsTwoNamedResponse = ""
    , events = []
    , error = Nothing
    }


type alias Model =
    { tests : Maybe (Dict Int Test)
    , returnsTwoNamedResponse : String
    , events : List String
    , error : Maybe Error
    }


testCommands : Config -> List (Cmd Msg)
testCommands config =
    [ Task.attempt (CallReturnsOneNamed "returnsOneNamed.call") (Contract.call config.contract <| TC.returnsOneNamed (BigInt.fromInt 12) (BigInt.fromInt 11))
    , Task.attempt (CallReturnsOneUnnamed "returnsOneUnnamed.call") (Contract.call config.contract <| TC.returnsOneUnnamed (BigInt.fromInt 30) (BigInt.fromInt 12))
    , Task.attempt (CallReturnsTwoNamed "returnsTwoNamed.call") (Contract.call config.contract <| TC.returnsTwoNamed (BigInt.fromInt 400) (BigInt.fromInt 20))
    , Task.attempt (CallReturnsTwoUnnamed "returnsTwoUnnamed.call") (Contract.call config.contract <| TC.returnsTwoUnnamed (BigInt.fromInt 4000) (BigInt.fromInt 4000))
    , Task.attempt (CallTriggerEvent "triggerEvent.call") (Contract.call config.contract <| TC.triggerEvent (BigInt.fromInt 4000))
    , Task.attempt (EstimateContractABI "estimateContractABI") (TC.encodeContractABI (BigInt.fromInt 23) "Testing123")
    , Task.attempt (EstimateContractGas "estimateContractGas") (TC.estimateContractGas (BigInt.fromInt 23) "Testing123")
    ]


viewTest : Test -> Element Styles Variations Msg
viewTest test =
    row TestRow
        [ spacing 20, paddingXY 20 20 ]
        [ column TestPassed [ vary Pass test.passed, vary Fail (not test.passed), verticalCenter ] [ text <| toString test.passed ]
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
                [ button Button [ onClick InitTests, paddingXY 20 0 ] (text "Start Tests")
                , button Button [ onClick InitEventOnce, paddingXY 20 0 ] (text "Watch Event Once")
                , button Button [ onClick InitEventSubscribe, paddingXY 20 0 ] (text "Subscribe")
                , button Button [ onClick InitEventUnsubscribe, paddingXY 20 0 ] (text "Unsubscribe")
                , button Button [ onClick InitMethodSend, paddingXY 20 0 ] (text "Send Tx w/ Event")
                , button Button [ onClick InitDeploy, paddingXY 20 0 ] (text "Deploy Contract")
                ]
            ]

        events =
            [ viewTest
                (Test
                    ("Events: " ++ toString (List.length model.events))
                    (toString model.events)
                    True
                )
            ]
    in
        column None
            [ width fill, scrollbars ]
            (titleRow ++ testButton ++ events ++ testsTable)


type Msg
    = InitDeploy
    | ContractDeployInfo String (Result Error ContractInfo)
    | InitMethodSend
    | MethodSendResponse String (Result Error TxId)
    | InitEventOnce
    | InitEventSubscribe
    | InitEventUnsubscribe
    | EventInfo (Result Error (EventLog { mathematician : Address, anInt : BigInt }))
    | InitTests
    | EstimateContractABI String (Result Error Hex)
    | EstimateContractGas String (Result Error Int)
    | CallReturnsOneNamed String (Result Error BigInt)
    | CallReturnsOneUnnamed String (Result Error BigInt)
    | CallReturnsTwoNamed String (Result Error { someUint : BigInt, someString : String })
    | CallReturnsTwoUnnamed String (Result Error { v0 : BigInt, v1 : String })
    | CallTriggerEvent String (Result Error String)


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    let
        updateTest key val =
            Just <| Dict.insert key val (model.tests ?= Dict.empty)

        updateModel key funcName result =
            case result of
                Ok val ->
                    { model | tests = updateTest key (Test funcName (toString val) True) }

                Err (Error err) ->
                    { model | tests = updateTest key { name = funcName, response = (toString err), passed = False } }
    in
        case msg of
            InitDeploy ->
                model
                    ! [ Task.attempt (ContractDeployInfo "contract.deploy")
                            (TC.deploy config.account Nothing (BigInt.fromInt 23) "testing123")
                      ]

            ContractDeployInfo funcName result ->
                updateModel 1 funcName result ! []

            InitMethodSend ->
                model
                    ! [ Task.attempt
                            (MethodSendResponse "triggerEvent.send")
                            (Contract.send config.account config.contract <| TC.triggerEvent (BigInt.fromInt 400))
                      ]

            MethodSendResponse funcName result ->
                updateModel 3 funcName result ! []

            InitEventOnce ->
                model
                    ! [ Task.attempt EventInfo (Contract.once config.contract TC.onceAdd) ]

            InitEventSubscribe ->
                model
                    ! [ TC.subscribeAdd ( config.contract, "eventWatchTest" ) ]

            InitEventUnsubscribe ->
                model
                    ! [ Contract.unsubscribe ( config.contract, "eventWatchTest" ) ]

            EventInfo result ->
                { model | events = toString result :: model.events } ! []

            InitTests ->
                model ! testCommands config

            EstimateContractABI funcName result ->
                updateModel 100 funcName result ! []

            EstimateContractGas funcName result ->
                updateModel 101 funcName result ! []

            CallReturnsOneNamed funcName result ->
                updateModel 110 funcName result ! []

            CallReturnsOneUnnamed funcName result ->
                updateModel 120 funcName result ! []

            CallReturnsTwoNamed funcName result ->
                updateModel 130 funcName result ! []

            CallReturnsTwoUnnamed funcName result ->
                updateModel 140 funcName result ! []

            CallTriggerEvent funcName result ->
                updateModel 150 funcName result ! []
