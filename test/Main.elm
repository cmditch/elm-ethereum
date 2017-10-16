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
import Pages.Eth as Eth
import Pages.Contract as Contract
import Web3.Types exposing (..)
import Web3.Eth
import Web3.Eth.Wallet as EthWallet
import Web3.Eth.Contract as EthContract
import TestContract as TC


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
    , ethModel : Eth.Model
    , contractModel : Contract.Model
    , error : Maybe Error
    }


init : ( Model, Cmd Msg )
init =
    { currentPage = Home
    , config = Config.ropstenConfig
    , homeModel = Home.init
    , utilsModel = Utils.init
    , accountsModel = Accounts.init
    , walletModel = Wallet.init
    , ethModel = Eth.init
    , contractModel = Contract.init
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

        Eth ->
            Eth.view model.ethModel |> Element.map EthMsg

        Contract ->
            Contract.view model.contractModel |> Element.map ContractMsg

        _ ->
            column None
                [ center, width fill, padding 100 ]
                [ text <| "No tests for " ++ toString model.currentPage ++ " yet."
                , decorativeImage Logo [ moveDown 200, height (px 600), width (px 800) ] { src = "../elm-web3-logo.svg" }
                ]


logo : List (Element Styles Variations Msg)
logo =
    [ decorativeImage Logo [ alignTop ] { src = "../elm-web3-logo.svg" } ]


drawer : Element Styles Variations Msg
drawer =
    let
        pages =
            [ Home, Utils, Eth, Accounts, Wallet, Contract, Events ]

        pageButton page =
            button Button [ onClick <| SetPage page ] (text <| toString page)
    in
        column Drawer
            [ height fill, spacing 10, padding 10, width (px 180) ]
            (logo ++ List.map pageButton pages)


type Msg
    = EstablishNetworkId (Result Error Int)
    | HomeMsg Home.Msg
    | UtilsMsg Utils.Msg
    | AccountsMsg Accounts.Msg
    | WalletMsg Wallet.Msg
    | EthMsg Eth.Msg
    | ContractMsg Contract.Msg
    | SetPage Page
    | NoOpTask (Result Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EstablishNetworkId result ->
            let
                ( newModel, newCmds ) =
                    update (SetPage Contract) model
            in
                case result of
                    Ok networkId ->
                        { newModel | config = getConfig <| getNetwork networkId }
                            ! [ newCmds, Task.attempt NoOpTask (EthWallet.add <| PrivateKey "0x7123d83b9d4314a91a5ea62d3678576d10352f538aaa2dc34ded3725c80740d8") ]

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

        EthMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Eth.update model.config subMsg model.ethModel
            in
                { model | ethModel = subModel } ! [ Cmd.map EthMsg subCmd ]

        ContractMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Contract.update model.config subMsg model.contractModel
            in
                { model | contractModel = subModel } ! [ Cmd.map ContractMsg subCmd ]

        SetPage page ->
            { model | currentPage = page } ! []

        NoOpTask _ ->
            model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ EthContract.eventSentry
            ( model.config.contract, "eventWatchTest" )
            (TC.decodeAdd >> Contract.EventInfo >> ContractMsg)
        ]
