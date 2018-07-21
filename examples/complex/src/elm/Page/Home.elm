module Page.Home exposing (Model, Msg, init, update, view, modalOpen)

-- Library

import BigInt
import Eth.Types exposing (Address)
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (onClick)
import Http
import Task


--Internal

import Data.Chain as ChainData exposing (NodePath)
import Contracts.WidgetFactory as Widget exposing (Widget)
import Request.Chain as ChainReq
import Request.Status exposing (RemoteData(..))
import Route
import Views.Styles exposing (Styles(..), Variations(..))
import Eth.Sentry.ChainCmd as ChainCmd exposing (ChainCmd)
import Page.WidgetWizard as WidgetWizard


type alias Model =
    { modal : Maybe WidgetWizard.Model
    , widgets : RemoteData Http.Error (List Widget)
    , errors : List Http.Error
    }


init : NodePath -> ( Model, Cmd Msg )
init nodePath =
    { modal = Nothing, widgets = Loading, errors = [] }
        ! [ Task.attempt WidgetResponse <| ChainReq.getWidgetList nodePath.http ChainData.widgetFactory ]


view : Maybe Address -> Model -> Element Styles Variations Msg
view mAccount model =
    let
        widgetList =
            case model.widgets of
                Success [] ->
                    text "Make sure you are on the Ropsten Network"

                Success widgets ->
                    column None
                        [ spacing 10 ]
                        (List.map viewWidget widgets)

                Failure e ->
                    column None
                        [ spacing 10 ]
                        [ text "Failure loading widgets", text <| toString e ]

                Loading ->
                    column None
                        [ spacing 10, center, paddingTop 250 ]
                        [ el Header [ vary H4 True ] <| text "Loading Widgets..."
                        , decorativeImage None [ width (percent 10), center, paddingTop 15 ] { src = "static/img/loader.gif" }
                        ]

                NotAsked ->
                    text "Shouldn't be seeing this"
    in
        column None
            [ padding 30, width fill, height fill, center ]
            [ whenJust model.modal <| Element.map ModalMsg << WidgetWizard.view mAccount
            , column None
                [ width (percent 75), spacing 20 ]
                [ row None
                    [ verticalCenter, spread ]
                    [ el Header [ vary H2 True ] <| text "WidgetList"
                    , el Button [ padding 10, onClick ModalOpen ] <| text "+ New Widget"
                    ]
                , widgetList
                ]
            ]


viewWidget : Widget -> Element Styles Variations Msg
viewWidget widget =
    Route.link (Route.Widget widget.id) <|
        column WidgetSummary
            [ width (px 500), height (px 75), center, verticalCenter ]
            [ el WidgetText [ vary H2 True ] (text <| "Widget # " ++ BigInt.toString widget.id)
            , el WidgetText [] (text "Click for more info")
            ]


modalOpen : Model -> Bool
modalOpen model =
    case model.modal of
        Nothing ->
            False

        Just _ ->
            True


type Msg
    = NoOp
    | WidgetResponse (Result Http.Error (List Widget))
    | ModalOpen
    | ModalMsg WidgetWizard.Msg


update : NodePath -> Msg -> Model -> ( Model, Cmd Msg, ChainCmd Msg )
update nodePath msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none, ChainCmd.none )

        WidgetResponse result ->
            case result of
                Ok ops ->
                    ( { model | widgets = Success <| List.reverse ops }, Cmd.none, ChainCmd.none )

                Err e ->
                    ( { model | widgets = Failure e, errors = e :: model.errors }, Cmd.none, ChainCmd.none )

        ModalOpen ->
            ( { model | modal = Just WidgetWizard.init }, Cmd.none, ChainCmd.none )

        ModalMsg subMsg ->
            case model.modal of
                Nothing ->
                    ( model, Cmd.none, ChainCmd.none )

                Just modal ->
                    let
                        ( newModel, newCmds, newChainEffs ) =
                            let
                                ( newModal, newModalCmd, newModalChainEff ) =
                                    WidgetWizard.update subMsg modal
                            in
                                ( { model | modal = Just newModal }
                                , Cmd.map ModalMsg newModalCmd
                                , ChainCmd.map ModalMsg newModalChainEff
                                )
                    in
                        case subMsg of
                            WidgetWizard.Close ->
                                ( { model | modal = Nothing }, Cmd.none, ChainCmd.none )

                            WidgetWizard.WidgetDeployed _ ->
                                ( newModel
                                , Cmd.batch
                                    [ Task.attempt WidgetResponse <| ChainReq.getWidgetList nodePath.http ChainData.widgetFactory
                                    , newCmds
                                    ]
                                , newChainEffs
                                )

                            _ ->
                                ( newModel, newCmds, newChainEffs )
