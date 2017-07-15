module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (value)
import Html.Events exposing (onClick, onInput)
import Web3 exposing (..)
import Web3.Eth exposing (getBlockNumber, decodeBlockNumber, Error(..))
import Web3.Eth.Types exposing (Block)
import Task


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


type alias Model =
    { currentBlockNumber : Maybe Int
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { currentBlockNumber = Nothing
    , error = Nothing
    }
        ! []


view : Model -> Html Msg
view model =
    div []
        [ viewBlockNumber model.currentBlockNumber
        , button [ onClick GetBlockNumber ] [ text "Get BlockNumber" ]
        , br [] []
        , br [] []
        , viewError model
        ]


viewBlockNumber : Maybe Int -> Html Msg
viewBlockNumber blockNumber =
    case blockNumber of
        Nothing ->
            div [] [ text "Press button to retrieve current block number" ]

        Just blockNumber_ ->
            div [] [ text <| toString blockNumber_ ]


viewBlock : Maybe Block -> Html Msg
viewBlock block =
    case block of
        Nothing ->
            div [] [ text "Press to retrieve block data" ]

        Just block_ ->
            div [] [ text <| toString block_ ]


viewError : Model -> Html Msg
viewError model =
    case model.error of
        Nothing ->
            span [] []

        Just err ->
            div [] [ text err ]


stringToMaybeInt : String -> Maybe Int
stringToMaybeInt =
    String.toInt >> Result.toMaybe


type Msg
    = GetBlockNumber
    | GetBlockNumberResponse (Result Web3.Eth.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetBlockNumber ->
            model ! [ getBlockNumber GetBlockNumberResponse ]

        GetBlockNumberResponse (Ok blockNumber_) ->
            case Web3.Eth.decodeBlockNumber blockNumber_ of
                Ok blockNumber ->
                    ( { model | currentBlockNumber = Just blockNumber, error = Nothing }, Cmd.none )

                Err error ->
                    { model | currentBlockNumber = Nothing, error = Just error } ! [ Debug.log error Cmd.none ]

        GetBlockNumberResponse (Err error_) ->
            case error_ of
                Error error ->
                    { model | currentBlockNumber = Nothing, error = Just error } ! []
