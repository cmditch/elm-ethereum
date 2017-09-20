module Main exposing (..)

import Html exposing (Html)
import Task exposing (Task)
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Config as Config
import Pages.Home as Home
import Pages.Utils as Utils
import Web3.Types exposing (..)
import Web3.Eth


-- import Web3
-- import Html.Events exposing (onClick)
-- import Dict exposing (Dict)
-- import BigInt exposing (BigInt)
-- import Web3.Utils
-- import Web3.Eth.Contract as Contract
-- import Web3.Eth.Accounts as Accounts
-- import Web3.Eth.Wallet as Wallet
-- import TestContract as TC
-- import Helpers exposing (Config, retryThrice)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { currentPage : Page
    , config : Config
    , homeModel : Home.Model
    , utilsModel : Utils.Model
    , error : Maybe Error
    }


init : ( Model, Cmd Msg )
init =
    { currentPage = Home
    , config = Config.mainnetConfig
    , homeModel = Home.init
    , utilsModel = Utils.init
    , error = Nothing
    }
        ! [ Task.attempt EstablishNetworkId (retryThrice Web3.Eth.getId) ]


type Page
    = Home
    | Utils
    | Eth
    | Account
    | Wallet
    | Contract
    | Events


view : Model -> Html Msg
view model =
    Element.viewport stylesheet <|
        column None
            [ height fill ]
            [ row None
                [ height fill, width fill ]
                [ drawer
                , viewPage model
                ]
            ]


viewPage : Model -> Element Styles variation Msg
viewPage model =
    case model.currentPage of
        Home ->
            Home.view model.homeModel |> Element.map HomeMsg

        Utils ->
            Utils.view model.utilsModel |> Element.map UtilsMsg

        _ ->
            text "No tests here yet"


drawer : Element Styles variation Msg
drawer =
    let
        pages =
            [ Home, Utils, Eth, Account, Wallet, Contract, Events ]

        pageButton page =
            button None [ onClick <| SetPage page ] (text <| toString page)
    in
        column Drawer
            [ height fill, spacing 10, padding 10, width (px 180) ]
            (List.map pageButton pages)


testTable : Model -> Element Styles variation Msg
testTable model =
    column Table
        [ width fill, spacing 10, padding 10 ]
        []


type Msg
    = EstablishNetworkId (Result Error Int)
    | HomeMsg Home.Msg
    | UtilsMsg Utils.Msg
    | SetPage Page


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EstablishNetworkId result ->
            case result of
                Ok networkId ->
                    let
                        config =
                            getConfig <| getNetwork networkId
                    in
                        { model | config = config } ! []

                Err err ->
                    { model | error = Just err } ! []

        HomeMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Home.update subMsg model.homeModel
            in
                { model | homeModel = subModel } ! [ Cmd.map HomeMsg subCmd ]

        UtilsMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Utils.update model.config subMsg model.utilsModel
            in
                { model | utilsModel = subModel } ! [ Cmd.map UtilsMsg subCmd ]

        SetPage page ->
            case page of
                Home ->
                    { model | currentPage = page } ! []

                Utils ->
                    if model.utilsModel.tests == Nothing then
                        { model | currentPage = page }
                            ! (Utils.testCommands model.config |> List.map (Cmd.map UtilsMsg))
                    else
                        { model | currentPage = page } ! []

                _ ->
                    { model | currentPage = page } ! []



-- UtilsMsg subMsg ->
--     toPage Utils UtilsMsg Utils.update subMsg model.utilsModel


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []
