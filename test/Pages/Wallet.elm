module Pages.Wallet exposing (..)

import Element exposing (..)
import Config exposing (..)
import Task exposing (Task)
import Dict exposing (Dict)
import Web3.Types exposing (..)
import Element.Attributes exposing (..)
import Web3.Eth.Wallet as Wallet
import Element.Events exposing (..)


init : Model
init =
    { wallet = Dict.empty
    , walletCount = 0
    , error = Nothing
    }


type alias Model =
    { wallet : Dict Int Account
    , walletCount : Int
    , error : Maybe Error
    }


initCreateAccount : Cmd Msg
initCreateAccount =
    Task.attempt WalletDict Wallet.create


viewAccountTests : Model -> List (Element Styles Variations Msg)
viewAccountTests model =
    let
        createWallet =
            row TestRow
                [ spacing 20, paddingXY 20 20 ]
                [ column None [] [ button None [ onClick InitCreate ] (text "Create") ] ]

        viewAccount ( index, account ) =
            row TestResponse
                [ verticalCenter ]
                [ text <| toString index
                , column None
                    [ spacing 3, padding 15 ]
                    [ text <| toString account.address, text <| toString account.privateKey ]
                ]

        viewWallet =
            row TestRow
                [ spacing 20, paddingXY 20 13, scrollbars, maxHeight (px 200) ]
                [ column None
                    [ spacing 15 ]
                    [ button None [ onClick InitCreate, width (px 230) ] (text "Create Account") ]
                , column None [] <|
                    (zip (Dict.keys model.wallet) (Dict.values model.wallet)
                        |> List.map viewAccount
                    )
                ]

        viewTestRow name elements =
            row TestRow
                [ spacing 20, paddingXY 20 0 ]
                [ column TestName [ verticalCenter, minWidth (px 180), paddingXY 0 15 ] [ text name ]
                , column VerticalBar [] []
                , row TestResponse
                    [ verticalCenter, paddingXY 0 10, xScrollbar ]
                    [ column TestResponse [ spacing 5, padding 10 ] elements ]
                ]

        viewWalletCount =
            viewTestRow "Wallet Count" [ text <| toString model.walletCount ]
    in
        case Dict.isEmpty model.wallet of
            True ->
                [ createWallet ]

            False ->
                [ viewWallet, viewWalletCount ]


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
    | InitCreateMany Int
    | WalletDict (Result Error (Dict Int Account))
    | Length (Result Error Int)


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        InitCreate ->
            model ! [ Task.attempt WalletDict Wallet.create ]

        InitCreateMany num ->
            model ! []

        WalletDict result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok wallet ->
                    { model | wallet = wallet } ! [ Task.attempt Length Wallet.length ]

        Length result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok length ->
                    { model | walletCount = length } ! []
