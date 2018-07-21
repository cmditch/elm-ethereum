module Main exposing (..)

-- Libraries

import Element exposing (..)
import Element.Attributes exposing (..)
import Eth.Sentry.Wallet as WalletSentry exposing (WalletSentry)
import Eth.Sentry.ChainCmd as ChainCmd exposing (ChainCmd)
import Eth.Sentry.Event as EventSentry exposing (EventSentry)
import Eth.Sentry.Tx as TxSentry exposing (TxSentry)
import Eth.Types exposing (..)
import Eth.Net as EthNet exposing (NetworkId(..))
import Html exposing (Html)
import Navigation exposing (Location)


--Internal

import Data.Chain as ChainData
import Page.Home as Home
import Page.Login as Login
import Page.Widget as Widget
import Ports
import Route exposing (Route)
import Request.UPort as UPort
import Views.Styles exposing (Styles(..), Variations(..), stylesheet)
import Page.WidgetWizard as WidgetWizard


main : Program Flags Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias EthNetworkId =
    Int


type alias Flags =
    Maybe EthNetworkId


type alias Model =
    { page : Page
    , account : Maybe Address
    , uPortUser : Maybe UPort.User
    , networkId : Maybe NetworkId
    , nodePath : ChainData.NodePath
    , isLoggedIn : Bool
    , eventSentry : EventSentry Msg
    , txSentry : TxSentry Msg
    , errors : List String
    }


type Modal
    = OppWizard WidgetWizard.Model


type Page
    = NotFound
    | Home Home.Model
    | Login Login.Model
    | Widget Widget.Model


init : Flags -> Location -> ( Model, Cmd Msg )
init rawNetworkID location =
    let
        networkId =
            Maybe.map EthNet.toNetworkId rawNetworkID

        nodePath =
            Maybe.withDefault Mainnet networkId
                |> ChainData.nodePath
    in
        setRoute (Route.fromLocation location)
            { page = Login (Tuple.first Login.init)
            , account = Nothing
            , uPortUser = Nothing
            , networkId = networkId
            , nodePath = nodePath
            , isLoggedIn = False
            , eventSentry =
                EventSentry.init EventSentryMsg nodePath.ws
                    |> EventSentry.withDebug
            , txSentry =
                TxSentry.init ( Ports.txOut, Ports.txIn ) TxSentryMsg nodePath.http
                    |> TxSentry.withDebug
            , errors = []
            }



-- VIEW


view : Model -> Html Msg
view model =
    Element.viewport stylesheet <|
        row None
            [ width fill
            , height (percent 100)
            , minHeight (percent 100)
            , inlineStyle [ ( "position", "fixed" ) ]
            ]
            [ when (modalOpen model.page) viewOverlay
            , when (model.isLoggedIn) <| viewSidebar model
            , el None [ height fill, width fill, yScrollbar ] <|
                case model.page of
                    NotFound ->
                        text "Page Not Found"

                    Home homeModel ->
                        Home.view model.account homeModel
                            |> Element.map HomeMsg

                    Login loginModel ->
                        Login.view model.account loginModel
                            |> Element.map LoginMsg

                    Widget oppModel ->
                        Widget.view model.account oppModel
                            |> Element.map WidgetMsg
            ]


viewOverlay : Element Styles Variations Msg
viewOverlay =
    el None
        [ inlineStyle
            [ ( "position", "fixed" )
            , ( "display", "block" )
            , ( "width", "100%" )
            , ( "height", "100%" )
            , ( "top", "0" )
            , ( "bottom", "0" )
            , ( "left", "0" )
            , ( "right", "0" )
            , ( "background-color", "rgba(0, 0, 0, 0.5)" )
            , ( "z-index", "1001" )
            ]
        ]
        empty


viewSidebar : Model -> Element Styles Variations Msg
viewSidebar model =
    let
        imageUrl path =
            "url(\"" ++ path ++ "\")"

        avatar user =
            column None
                [ spacing 10, center ]
                [ circle 50
                    ProfileImage
                    [ inlineStyle
                        [ ( "background-image", imageUrl user.avatar )
                        , ( "background-size", "cover" )
                        , ( "background-repeat", "no-repeat" )
                        , ( "background-position", "center" )
                        ]
                    ]
                    empty
                , el WidgetText [ vary WidgetWhite True ] <| text user.name
                , el WidgetText [ vary WidgetWhite True, vary Small True ] <| text user.email
                ]
    in
        column Sidebar
            [ center, height (percent 100), minHeight (percent 100), padding 30, spacing 30 ]
            [ whenJust model.uPortUser (\user -> avatar user)
            , viewNetworkStatus model.networkId
            ]


viewNetworkStatus : Maybe NetworkId -> Element Styles Variations msg
viewNetworkStatus networkId =
    let
        ( style, display ) =
            case networkId of
                Nothing ->
                    ( StatusFailure, "Disconnected" )

                Just Mainnet ->
                    ( StatusSuccess, "Mainnet" )

                Just network ->
                    ( StatusAlert, EthNet.networkIdToString network )
    in
        row Status
            [ verticalCenter, center, spacing 5, height fill, width fill, alignBottom ]
            [ circle 5.0 style [ verticalCenter ] empty
            , text display
            ]


modalOpen : Page -> Bool
modalOpen page =
    case page of
        Home model ->
            Home.modalOpen model

        _ ->
            False



-- UPDATE


type Msg
    = NoOp
    | SetRoute (Maybe Route)
      -- Page Msgs
    | HomeMsg Home.Msg
    | LoginMsg Login.Msg
    | WidgetMsg Widget.Msg
      -- Port/Sub Related Msgs
    | WalletStatus WalletSentry
    | EventSentryMsg EventSentry.Msg
    | TxSentryMsg TxSentry.Msg
    | Fail String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updatePage model.page msg model


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    let
        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                { model | page = (toModel newModel) }
                    ! [ Cmd.map toMsg newCmd ]

        toChainEffPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd, chainEff ) =
                    subUpdate subMsg subModel

                ( ( newTxSentry, newEventSentry ), chainCmds ) =
                    ChainCmd.execute ( model.txSentry, model.eventSentry ) (ChainCmd.map toMsg chainEff)
            in
                { model
                    | txSentry = newTxSentry
                    , eventSentry = newEventSentry
                    , page = (toModel newModel)
                }
                    ! [ chainCmds, Cmd.map toMsg newCmd ]
    in
        case ( page, msg ) of
            {- Route Updates -}
            ( _, SetRoute route ) ->
                setRoute route model

            {- Page Updates -}
            ( Login subModel, LoginMsg subMsg ) ->
                case subMsg of
                    Login.LoggedIn user ->
                        { model | isLoggedIn = True, uPortUser = Just user } ! [ Navigation.newUrl "#" ]

                    Login.SkipLogin ->
                        { model | isLoggedIn = True } ! [ Navigation.newUrl "#" ]

                    _ ->
                        toPage Login LoginMsg Login.update subMsg subModel

            ( Home subModel, HomeMsg subMsg ) ->
                toChainEffPage Home HomeMsg (Home.update model.nodePath) subMsg subModel

            ( Widget subModel, WidgetMsg subMsg ) ->
                toChainEffPage Widget WidgetMsg (Widget.update model.nodePath) subMsg subModel

            {- Sentry -}
            ( _, WalletStatus walletSentry ) ->
                { model
                    | account = walletSentry.account
                    , nodePath = ChainData.nodePath walletSentry.networkId
                }
                    ! []

            ( _, TxSentryMsg subMsg ) ->
                let
                    ( newTxSentry, newMsg ) =
                        TxSentry.update subMsg model.txSentry
                in
                    { model | txSentry = newTxSentry }
                        ! [ newMsg ]

            ( _, EventSentryMsg subMsg ) ->
                let
                    ( newEventSentry, newSubMsg ) =
                        EventSentry.update subMsg model.eventSentry
                in
                    { model | eventSentry = newEventSentry }
                        ! [ newSubMsg ]

            {- Failures and NoOps -}
            ( _, NoOp ) ->
                model ! []

            ( _, Fail str ) ->
                { model | errors = str :: model.errors }
                    ! []

            ( _, _ ) ->
                model ! []


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =
    case ( maybeRoute, model.isLoggedIn ) of
        ( Just Route.Login, False ) ->
            let
                ( subModel, subCmd ) =
                    Login.init
            in
                { model | page = Login subModel }
                    ! [ Cmd.map LoginMsg subCmd ]

        ( Just Route.Login, True ) ->
            model ! [ Navigation.newUrl "#" ]

        ( _, False ) ->
            model ! [ Navigation.newUrl "#login" ]

        ( Nothing, _ ) ->
            { model | page = NotFound } ! []

        ( Just Route.Home, _ ) ->
            let
                ( subModel, subCmd ) =
                    Home.init model.nodePath
            in
                { model | page = (Home subModel) }
                    ! [ Cmd.map HomeMsg subCmd ]

        ( Just (Route.Widget id), _ ) ->
            let
                ( widgetSubModel, widgetSubCmd ) =
                    Widget.init model.nodePath id
            in
                { model | page = Widget widgetSubModel }
                    ! [ Cmd.map WidgetMsg widgetSubCmd ]



-- SUBSCRIPTION


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ pageSubscriptions model.page
        , Ports.walletSentry (WalletSentry.decodeToMsg Fail WalletStatus)
        , EventSentry.listen model.eventSentry
        , TxSentry.listen model.txSentry
        ]


pageSubscriptions : Page -> Sub Msg
pageSubscriptions page =
    case page of
        Login model ->
            Sub.map LoginMsg <| Login.subscriptions model

        _ ->
            Sub.none
