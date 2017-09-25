module Main exposing (..)

import Html exposing (Html)
import Task exposing (Task)
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Config exposing (..)
import Pages.Home as Home exposing (Msg(..))
import Pages.Utils as Utils
import Pages.Accounts as Accounts
import Pages.Wallet as Wallet
import Web3.Types exposing (..)
import Web3.Eth


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
    , accountsModel : Accounts.Model
    , walletModel : Wallet.Model
    , error : Maybe Error
    }


init : ( Model, Cmd Msg )
init =
    { currentPage = Home
    , config = Config.mainnetConfig
    , homeModel = Home.init
    , utilsModel = Utils.init
    , accountsModel = Accounts.init
    , walletModel = Wallet.init
    , error = Nothing
    }
        ! [ Task.attempt EstablishNetworkId (retryThrice Web3.Eth.getId) ]


type Page
    = Home
    | Utils
    | Eth
    | Accounts
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


viewPage : Model -> Element Styles Variations Msg
viewPage model =
    case model.currentPage of
        Utils ->
            Utils.view model.utilsModel |> Element.map UtilsMsg

        Accounts ->
            Accounts.view model.accountsModel |> Element.map AccountsMsg

        Wallet ->
            Wallet.view model.walletModel |> Element.map WalletMsg

        _ ->
            column None
                [ verticalCenter, center, width fill ]
                [ text <| "No tests for " ++ toString model.currentPage ++ " yet." ]


drawer : Element Styles Variations Msg
drawer =
    let
        pages =
            [ Home, Utils, Eth, Accounts, Wallet, Contract, Events ]

        pageButton page =
            button None [ onClick <| SetPage page ] (text <| toString page)
    in
        column Drawer
            [ height fill, spacing 10, padding 10, width (px 180) ]
            (List.map pageButton pages)


type Msg
    = EstablishNetworkId (Result Error Int)
    | HomeMsg Home.Msg
    | UtilsMsg Utils.Msg
    | AccountsMsg Accounts.Msg
    | WalletMsg Wallet.Msg
    | SetPage Page


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EstablishNetworkId result ->
            let
                ( newModel, newCmds ) =
                    update (SetPage Wallet) model
            in
                case result of
                    Ok networkId ->
                        { newModel | config = getConfig <| getNetwork networkId }
                            ! [ newCmds ]

                    Err err ->
                        { newModel | error = Just err } ! []

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

        AccountsMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Accounts.update model.config subMsg model.accountsModel
            in
                { model | accountsModel = subModel } ! [ Cmd.map AccountsMsg subCmd ]

        WalletMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Wallet.update model.config subMsg model.walletModel
            in
                { model | walletModel = subModel } ! [ Cmd.map WalletMsg subCmd ]

        SetPage page ->
            { model | currentPage = page } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []
