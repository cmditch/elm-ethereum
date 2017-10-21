module Pages.Wallet exposing (..)

import Element exposing (..)
import Config exposing (..)
import Task exposing (Task)
import Dict exposing (Dict)
import Process
import Web3.Types exposing (..)
import Element.Attributes exposing (..)
import Web3.Eth.Wallet as Wallet
import Element.Events exposing (..)


init : Model
init =
    { wallet = Dict.empty
    , keystores = []
    , actionPanel = ShowWallet
    , walletCount = 0
    , saveStatus = ""
    , removeStatus = ""
    , loadStatus = ""
    , error = Nothing
    , keys = []
    }


type alias Model =
    { wallet : Dict Int Account
    , keystores : List Keystore
    , actionPanel : ActionPanel
    , walletCount : Int
    , saveStatus : String
    , removeStatus : String
    , loadStatus : String
    , error : Maybe Error
    , keys : List Int
    }


initCreateAccount : Cmd Msg
initCreateAccount =
    Task.attempt List Wallet.create


type ActionPanel
    = ShowWallet
    | ShowKeystores


viewAccountTests : Model -> List (Element Styles Variations Msg)
viewAccountTests model =
    let
        actionPanel =
            case model.actionPanel of
                ShowKeystores ->
                    column TestRow
                        [ spacing 20, paddingXY 20 13, scrollbars ]
                        [ viewError model.error
                        , row TestName [ center ] [ text "Encrypted Keystore" ]
                        , column None [ scrollbars, clip ] <| List.map (toString >> text) model.keystores
                        ]

                ShowWallet ->
                    column TestRow
                        [ spacing 20, paddingXY 20 13, scrollbars ]
                        [ viewError model.error
                        , row TestName [ center ] [ text "Wallet" ]
                        , column None [ scrollbars ] <|
                            (zip (Dict.keys model.wallet) (Dict.values model.wallet)
                                |> List.map viewAccount
                            )
                        ]

        viewAccount ( index, account ) =
            row TestResponse
                [ verticalCenter ]
                [ text <| toString index
                , column None
                    [ spacing 3, padding 15 ]
                    [ text <| toString account.address, text <| toString account.privateKey ]
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

        list =
            viewTestRow "List Wallet"
                [ button Button
                    [ onClick InitList, width (px 230) ]
                    (text "List")
                ]

        create =
            viewTestRow "Create Random Account"
                [ button Button
                    [ onClick InitCreate, width (px 230) ]
                    (text "Create")
                ]

        createMany =
            viewTestRow "Create Many"
                [ button Button
                    [ onClick (InitCreateMany)
                    , width (px 230)
                    ]
                    (text "Create 3")
                ]

        add =
            viewTestRow "Add Account"
                [ button Button
                    [ onClick (InitAdd)
                    , width (px 230)
                    ]
                    (text "Add 0xfBbBb...")
                ]

        remove =
            viewTestRow "Remove First Account"
                [ button Button
                    [ onClick (InitRemove)
                    , width (px 230)
                    ]
                    (text "Remove")
                , text model.removeStatus
                ]

        clear =
            viewTestRow "Clear Wallet"
                [ button Button
                    [ onClick (InitClear)
                    , width (px 230)
                    ]
                    (text "Clear")
                ]

        encrypt =
            viewTestRow "Encrypt Wallet"
                [ button Button
                    [ onClick (InitEncrypt)
                    , width (px 230)
                    ]
                    (text "Encrypt")
                ]

        decrypt =
            viewTestRow "Decrypt Wallet"
                [ button Button
                    [ onClick (InitDecrypt)
                    , width (px 230)
                    ]
                    (text "Decrypt")
                ]

        save =
            viewTestRow "Save Wallet"
                [ button Button
                    [ onClick InitSave
                    , width (px 230)
                    ]
                    (text "Save Wallet")
                , text model.saveStatus
                ]

        load =
            viewTestRow "Load Wallet"
                [ button Button
                    [ onClick InitLoad
                    , width (px 230)
                    ]
                    (text "Load Wallet")
                , text model.loadStatus
                ]
    in
        [ column None
            [ height fill ]
            [ viewWalletCount
            , list
            , create
            , createMany
            , remove
            , add
            , clear
            , encrypt
            , decrypt
            , save
            , load
            ]
        , column None
            [ width fill, scrollbars ]
            [ actionPanel ]
        ]


viewError : Maybe Error -> Element style variation msg
viewError error =
    case error of
        Just error ->
            text <| toString error

        Nothing ->
            text ""


titleRow : Model -> Element Styles Variations Msg
titleRow model =
    row TestTitle
        [ padding 30, center ]
        [ text "Web3.Eth.Wallet"
        ]


view : Model -> Element Styles Variations Msg
view model =
    column None
        [ width fill, scrollbars ]
        [ titleRow model
        , row None [ height fill ] (viewAccountTests model)
        ]


type Msg
    = InitList
    | InitCreate
    | InitCreateMany
    | InitAdd
    | InitRemove
    | InitClear
    | InitEncrypt
    | InitDecrypt
    | InitSave
    | InitLoad
    | List (Result Error (Dict Int Account))
    | Length (Result Error Int)
    | Save (Result Error Bool)
    | Remove (Result Error Bool)
    | Encrypt (Result Error (List Keystore))
    | ClearAlerts ()


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        InitList ->
            model ! [ Task.attempt List Wallet.list ]

        InitCreate ->
            model
                ! [ Task.attempt List Wallet.create ]

        InitCreateMany ->
            model ! [ Task.attempt List (Wallet.createMany 3) ]

        InitAdd ->
            model
                ! [ Task.attempt List
                        (Wallet.add (PrivateKey "0x7123d83b9d4314a91a5ea62d3678576d10352f538aaa2dc34ded3725c80740d8")
                            |> Task.andThen (\_ -> Wallet.list)
                        )
                  ]

        InitRemove ->
            model
                ! [ Task.attempt Remove (Wallet.remove (IntIndex 0)) ]

        InitClear ->
            model
                ! [ Task.attempt List Wallet.clear ]

        InitEncrypt ->
            case Dict.isEmpty model.wallet of
                True ->
                    { model | error = Just (Error "Nothing to Encrypt"), actionPanel = ShowKeystores } ! []

                False ->
                    model ! [ Task.attempt Encrypt <| Wallet.encrypt "qwerty" ]

        InitDecrypt ->
            case model.keystores of
                [] ->
                    { model | error = Just (Error "Nothing to Decrypt") } ! []

                keystores ->
                    model ! [ Task.attempt List <| Wallet.decrypt keystores "qwerty" ]

        InitSave ->
            { model | saveStatus = "Saving wallet...." }
                ! [ Task.attempt Save (Wallet.save "qwerty") ]

        InitLoad ->
            { model | loadStatus = "Loading wallet...." }
                ! [ Task.attempt List (Wallet.load "qwerty" |> Task.andThen (\_ -> Wallet.list)) ]

        List result ->
            case result of
                Err err ->
                    { model | error = Just err, actionPanel = ShowWallet } ! []

                Ok wallet ->
                    { model | wallet = wallet, loadStatus = "", actionPanel = ShowWallet }
                        ! [ Task.attempt Length Wallet.length ]

        Length result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok length ->
                    { model | walletCount = length } ! []

        Save result ->
            case result of
                Err err ->
                    { model | error = Just err, saveStatus = "Error Saving Wallet" }
                        ! [ clearAlerts ]

                Ok saveStatus ->
                    case saveStatus of
                        True ->
                            { model | saveStatus = "Successfully Saved!!" }
                                ! [ clearAlerts ]

                        False ->
                            { model | saveStatus = "Error Saving Wallet" }
                                ! [ clearAlerts ]

        Remove result ->
            case result of
                Err err ->
                    { model | error = Just err, removeStatus = "Error Removing Account" }
                        ! [ Task.attempt List Wallet.list ]

                Ok removeStatus ->
                    case removeStatus of
                        True ->
                            { model | removeStatus = "Successfully Removed!!" }
                                ! [ Task.attempt List Wallet.list, clearAlerts ]

                        False ->
                            { model | removeStatus = "Error Removing Account" }
                                ! [ Task.attempt List Wallet.list, clearAlerts ]

        Encrypt result ->
            case result of
                Err err ->
                    { model | error = Just err, actionPanel = ShowWallet } ! [ clearAlerts ]

                Ok keystores ->
                    { model | keystores = keystores, actionPanel = ShowKeystores } ! []

        ClearAlerts _ ->
            { model | saveStatus = "", removeStatus = "", loadStatus = "", error = Nothing }
                ! []


clearAlerts : Cmd Msg
clearAlerts =
    Task.perform ClearAlerts (Process.sleep 3000)
