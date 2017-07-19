module Main exposing (..)

import Task
import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Web3 exposing (Error(..), toTask)
import Web3.Eth exposing (getBlockNumber, getBlock)
import Web3.Eth.Types exposing (Address(..), Block)
import HodlBox


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
    , contractAddress : Address
    , hodlerAddress : Maybe Address
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { latestBlock = Nothing
    , contractAddress = Address "0x10070265733b0f064ee81f698437cd07137bb0ec"
    , hodlerAddress = Nothing
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
        , viewAddress model.hodlerAddress
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

        Just (Address addy) ->
            div [] [ text addy ]


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
    | HodlBoxResponse (Result Web3.Error Address)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ButtonPress ->
            model
                ! [ Task.attempt LatestResponse
                        (getBlockNumber
                            |> Task.andThen (\latest -> getBlock latest)
                        )
                  , Task.attempt HodlBoxResponse (HodlBox.hodler model.contractAddress)
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

        HodlBoxResponse response ->
            case response of
                Ok hodler ->
                    { model | hodlerAddress = Just hodler } ! []

                Err error ->
                    case error of
                        Web3.Error e ->
                            { model | hodlerAddress = Nothing, error = Just e } ! []

                        Web3.BadPayload e ->
                            { model | hodlerAddress = Nothing, error = Just ("decoding error: " ++ e) } ! []
