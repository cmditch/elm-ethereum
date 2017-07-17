module Main exposing (..)

import Task
import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Web3 exposing (Error(..), toTask)
import Web3.Eth exposing (getBlockNumber, getBlock)
import Web3.Eth.Types exposing (Address, Block)
import HodlBox exposing (hodling)
import BigInt exposing (BigInt)


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
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { latestBlock = Nothing
    , error = Nothing
    }
        ! []


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick LatestBlock ] [ text "Get latest block info" ]
        , br [] []
        , br [] []
        , viewBlock model.latestBlock
        , viewError model
        ]


viewBlock : Maybe Block -> Html Msg
viewBlock block =
    case block of
        Nothing ->
            div [] [ text "Hit that button, son" ]

        Just b ->
            div [] [ text <| toString b ]


viewError : Model -> Html Msg
viewError model =
    case model.error of
        Nothing ->
            span [] []

        Just err ->
            div [] [ text err ]


type Msg
    = LatestBlock
    | LatestResponse (Result Web3.Error Block)
    | HodlingResponse (Result Web3.Error BigInt)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LatestBlock ->
            model
                ! [ Task.attempt LatestResponse
                        (getBlockNumber
                            |> Task.andThen (\latest -> getBlock latest)
                        )
                  , Task.attempt HodlingResponse (hodling <| Web3.Eth.Types.Address "Testing console output")
                  ]

        LatestResponse response ->
            case response of
                Ok block ->
                    { model | latestBlock = Just block, error = Nothing } ! []

                Err error ->
                    case error of
                        Web3.Error e ->
                            { model | latestBlock = Nothing, error = Just e } ! []

                        Web3.BadPayload e ->
                            { model | latestBlock = Nothing, error = Just ("decoding error: " ++ e) } ! []

        HodlingResponse response ->
            case response of
                _ ->
                    model ! []
