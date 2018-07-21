module Page.WidgetWizard exposing (Model, Msg(Close, WidgetDeployed), init, view, update)

--Library

import BigInt exposing (BigInt)
import Element exposing (..)
import Element.Keyed as Keyed
import Element.Events exposing (..)
import Element.Attributes exposing (..)
import Element.Input as Input
import SelectList as SL exposing (SelectList)


--Internal

import Contracts.WidgetFactory as Widget exposing (Widget)
import Data.Chain as ChainData
import Views.Styles exposing (Styles(..), Variations(..))
import Views.Helpers exposing (viewBreadcrumbs, etherscanLink)
import Eth.Sentry.ChainCmd as ChainCmd exposing (ChainCmd)
import Eth
import Eth.Decode as Decode
import Eth.Units exposing (gwei)
import Eth.Utils as EthUtils
import Eth.Types exposing (..)


type FormStep
    = ConfirmAddress
    | WidgetSize
    | WidgetCost
    | Deploy
    | DeployPending
    | Deployed


type alias Model =
    { errors : List String
    , steps : SelectList FormStep
    , widgetSize : String
    , widgetCost : String
    }


init : Model
init =
    { errors = []
    , steps = SL.fromLists [] ConfirmAddress [ WidgetSize, WidgetCost, Deploy, DeployPending, Deployed ]
    , widgetSize = ""
    , widgetCost = ""
    }


view : Maybe Address -> Model -> Element Styles Variations Msg
view mAccount model =
    let
        titleBar =
            row None
                [ width fill, spread ]
                [ el Header [ vary H3 True, alignLeft ] <| text "Create New Widget"
                , button Button [ onClick Close, paddingXY 10 0 ] (text "X")
                ]
    in
        modal None
            [ height (percent 100), width (percent 100) ]
            (el None [ center, verticalCenter ] <|
                column ModalBox
                    [ width (px 800)
                    , height (px 500)
                    , center
                    , padding 15
                    , spacing 20
                    ]
                <|
                    case mAccount of
                        Nothing ->
                            [ titleBar
                            , text "No metamask account"
                            ]

                        Just account ->
                            [ titleBar
                            , viewBreadcrumbs stepToString ChangeStep Deployed model.steps
                            , viewOppWizard account model
                            ]
            )


viewOppWizard : Address -> Model -> Element Styles Variations Msg
viewOppWizard account model =
    let
        inputPad =
            padding 3

        textInput =
            Input.text ModalBoxSelection [ inputPad, inlineStyle [ ( "box-shadow", "none" ) ] ]
    in
        el None
            [ padding 20, height fill, width fill ]
        <|
            case SL.selected model.steps of
                ConfirmAddress ->
                    column None
                        [ height fill, width fill, center, verticalCenter, spacing 20 ]
                        [ row None
                            [ spacing 10, center ]
                            [ el WidgetText [ vary Bold True ] <| text "Your Account Address"
                            , etherscanLink account
                            ]
                        , el Button [ onClick <| ChangeStep WidgetSize, padding 10 ] <|
                            text "Continue"
                        ]

                WidgetSize ->
                    column None
                        [ height fill, width fill, center, verticalCenter, spacing 20 ]
                        [ row None
                            [ spacing 20 ]
                            [ column None
                                [ spacing 20, alignRight ]
                                [ el WidgetText [ vary Bold True ] <| text "Widget Size" ]
                            , Keyed.column None
                                [ spacing 20 ]
                                [ ( "00"
                                  , textInput
                                        { onChange = SetWidgetSize
                                        , value = model.widgetSize
                                        , label = Input.hiddenLabel ""
                                        , options = []
                                        }
                                  )
                                ]
                            ]
                        , el Button [ onClick <| ChangeStep WidgetCost, padding 10 ] (text "Next")
                        ]

                WidgetCost ->
                    column None
                        [ height fill, width fill, center, verticalCenter, spacing 20 ]
                        [ row None
                            [ spacing 20 ]
                            [ column None
                                [ spacing 20, alignRight ]
                                [ el WidgetText [ vary Bold True ] <| text "Widget Cost" ]
                            , Keyed.column None
                                [ spacing 20 ]
                                [ ( "01"
                                  , textInput
                                        { onChange = SetWidgetCost
                                        , value = model.widgetCost
                                        , label = Input.hiddenLabel ""
                                        , options = []
                                        }
                                  )
                                ]
                            ]
                        , el Button [ onClick <| ChangeStep Deploy, padding 10 ] <|
                            text "Next"
                        ]

                Deploy ->
                    case makeTxParams account model of
                        Nothing ->
                            column None
                                [ height fill, width fill, center, verticalCenter ]
                                [ text "Something is wrong with your form data" ]

                        Just txParams ->
                            column None
                                [ height fill, width fill, center, verticalCenter ]
                                [ row None
                                    [ spacing 20 ]
                                    [ column None
                                        [ spacing 20, alignRight ]
                                        [ el WidgetText [ vary Bold True ] <| text "Size"
                                        , el WidgetText [ vary Bold True ] <| text "Cost"
                                        ]
                                    , column None
                                        [ spacing 20 ]
                                        [ el WidgetText [] <| text model.widgetSize
                                        , el WidgetText [] <| text model.widgetCost
                                        ]
                                    , column WidgetConfirm
                                        [ spacing 10, padding 20, verticalCenter, center ]
                                        [ el WidgetText [] <| text "Please Confirm"
                                        , el Button [ onClick <| DeployWidget txParams, padding 10 ] <| text "Create"
                                        ]
                                    ]
                                ]

                DeployPending ->
                    column None
                        [ height fill, width fill, center, verticalCenter, spacing 10 ]
                        [ el Header [ vary H4 True ] <| text "Creating Widget..."
                        , decorativeImage None [ width (percent 30), paddingTop 15 ] { src = "static/img/loader.gif" }
                        , el WidgetText [] <| text "Blockchainz is Miningz"
                        ]

                Deployed ->
                    column None
                        [ height fill, width fill, center, verticalCenter ]
                        [ el Header [ vary H4 True ] <| text "Widget Created!"
                        , el Button [ onClick Close, padding 10, moveDown 30 ] <| text "Return To Dashboard"
                        ]


stepToString : FormStep -> String
stepToString step =
    case step of
        ConfirmAddress ->
            "Verify Account"

        WidgetSize ->
            "Widget Info "

        WidgetCost ->
            "Widget Cost"

        Deploy ->
            "Confirmation"

        DeployPending ->
            "Deploying"

        Deployed ->
            "Widget Deployed"


makeTxParams : Address -> Model -> Maybe (Call ())
makeTxParams account model =
    Maybe.map2
        (\size cost ->
            Widget.newWidget ChainData.widgetFactory size cost account
                -- Can directly edit txParams like so
                |> (\txParams ->
                        { txParams
                            | value = Just <| BigInt.fromInt 0
                            , gasPrice = Just <| gwei 1337
                        }
                   )
        )
        (BigInt.fromString model.widgetSize)
        (BigInt.fromString model.widgetCost)


type Msg
    = NoOp
    | ChangeStep FormStep
    | SetWidgetSize String
    | SetWidgetCost String
    | DeployWidget (Call ())
    | WidgetDeployPending
    | WidgetDeployed (Event Widget.WidgetCreated)
    | Close
    | Fail String


update : Msg -> Model -> ( Model, Cmd Msg, ChainCmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            , ChainCmd.none
            )

        ChangeStep step ->
            ( { model | steps = SL.select ((==) step) model.steps }
            , Cmd.none
            , ChainCmd.none
            )

        SetWidgetSize val ->
            ( { model | widgetSize = val }
            , Cmd.none
            , ChainCmd.none
            )

        SetWidgetCost val ->
            ( { model | widgetCost = val }
            , Cmd.none
            , ChainCmd.none
            )

        DeployWidget txParams ->
            let
                logFilter =
                    (Widget.widgetCreatedEvent ChainData.widgetFactory)

                eventToMsg =
                    EthUtils.valueToMsg WidgetDeployed Fail (Decode.event Widget.widgetCreatedDecoder)

                txParams_ =
                    { txParams | gasPrice = Just <| gwei 20 }
                        |> Eth.toSend
            in
                ( model
                , Cmd.none
                , ChainCmd.batch
                    [ ChainCmd.watchEventOnce eventToMsg logFilter
                    , ChainCmd.sendTx (\_ -> WidgetDeployPending) txParams_
                    ]
                )

        WidgetDeployPending ->
            ( { model | steps = SL.select ((==) DeployPending) model.steps }
            , Cmd.none
            , ChainCmd.none
            )

        WidgetDeployed event ->
            ( { model | steps = SL.select ((==) Deployed) model.steps }
            , Cmd.none
            , ChainCmd.none
            )

        Close ->
            ( model
            , Cmd.none
            , ChainCmd.none
            )

        Fail str ->
            ( { model | errors = str :: model.errors }
            , Cmd.none
            , ChainCmd.none
            )
