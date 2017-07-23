module Main exposing (..)

import Task
import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Web3 exposing (Error(..), toTask)
import Web3.Eth.Types exposing (Address, Block, TxId, NewContract)
import TestBox
import BigInt


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


type alias Model =
    { latestBlock : Maybe Block
    , contractInfo : NewContract
    , coinbase : Address
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { latestBlock = Nothing
    , contractInfo = NewContract "TxId" "Contract Address"
    , coinbase = "0xe87529a6123a74320e13a6dabf3606630683c029"
    , error = Nothing
    }
        ! []


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick ButtonPress ] [ text "Touch web3 plz" ]
        , bigBreak
        , viewBlock model.latestBlock
        , bigBreak
        , text <| toString model.contractInfo
        , bigBreak
        , viewError model
        ]


bigBreak : Html Msg
bigBreak =
    div []
        [ br [] []
        , br [] []
        , br [] []
        ]


viewBlock : Maybe Block -> Html Msg
viewBlock block =
    case block of
        Nothing ->
            div [] [ text "Awaiting Block info..." ]

        Just block_ ->
            div [] [ text <| toString block_ ]


viewAddress : Maybe Address -> Html Msg
viewAddress address =
    case address of
        Nothing ->
            div [] [ text "Awaiting Address info..." ]

        Just address_ ->
            div [] [ text address_ ]


viewError : Model -> Html Msg
viewError model =
    case model.error of
        Nothing ->
            span [] []

        Just err ->
            div [] [ text err ]


type Msg
    = ButtonPress
    | LatestResponse (Result Web3.Error Block)
    | TestBoxResponse (Result Web3.Error NewContract)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ButtonPress ->
            model
                ! [ Task.attempt TestBoxResponse (TestBox.new model.coinbase Nothing { age_ = BigInt.fromInt 424242 })
                  ]

        LatestResponse response ->
            case response of
                Ok block ->
                    { model | latestBlock = Just block } ! []

                Err error ->
                    case error of
                        Web3.Error e ->
                            { model | latestBlock = Nothing, error = Just e } ! []

                        Web3.BadPayload e ->
                            { model | latestBlock = Nothing, error = Just ("decoding error: " ++ e) } ! []

                        Web3.NoWallet ->
                            { model | latestBlock = Nothing, error = Just ("No Wallet Detected") } ! []

        TestBoxResponse response ->
            case response of
                Ok contractInfo ->
                    { model | contractInfo = contractInfo } ! []

                Err error ->
                    case error of
                        Web3.Error e ->
                            { model | contractInfo = NewContract "error" "derp", error = Just e } ! []

                        Web3.BadPayload e ->
                            { model | contractInfo = NewContract "Bad" "Payload", error = Just ("decoding error: " ++ e) } ! []

                        Web3.NoWallet ->
                            { model | contractInfo = NewContract "No" "Walzor", error = Just (" No Wallet Detected") } ! []
