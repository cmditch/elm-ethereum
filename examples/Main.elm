module Main exposing (..)

import Task
import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Web3 exposing (Error(..), toTask)
import Web3.Eth exposing (getBlockNumber, getBlock)
import Web3.Eth.Types exposing (Address, Block)
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
    , contractAddress : String
    , coinbase : Address
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { latestBlock = Nothing
    , contractAddress = "nada tostada"
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
        , text model.contractAddress
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
    | TestBoxResponse (Result Web3.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ButtonPress ->
            model
                ! [ Task.attempt LatestResponse
                        (getBlockNumber
                            |> Task.andThen (\latest -> getBlock latest)
                        )
                  , Task.attempt TestBoxResponse (TestBox.new model.coinbase Nothing { age_ = BigInt.fromInt 1239 })
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

        TestBoxResponse response ->
            case response of
                Ok contract ->
                    { model | contractAddress = contract } ! []

                Err error ->
                    case error of
                        Web3.Error e ->
                            { model | contractAddress = "error", error = Just e } ! []

                        Web3.BadPayload e ->
                            { model | contractAddress = "error", error = Just ("decoding error: " ++ e) } ! []
