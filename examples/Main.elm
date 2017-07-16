module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (value)
import Html.Events exposing (onClick, onInput)
import Web3
import Web3.Eth exposing (getBlockNumber, getBlock)
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
    , currentBlock : Maybe Block
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { currentBlockNumber = Nothing
    , currentBlock = Nothing
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
        , viewBlock model.currentBlock
        , button [ onClick (GetBlock 4000000) ] [ text "Get Block Number 4,000,000" ]
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
    | GetBlockNumberResponse (Result Web3.Error Int)
    | GetBlock Int
    | GetBlockResponse (Result Web3.Error Block)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetBlockNumber ->
            model ! [ Web3.send GetBlockNumberResponse getBlockNumber ]

        GetBlock n ->
            model ! [ Web3.send GetBlockResponse (getBlock n) ]

        GetBlockNumberResponse response ->
            case response of
                Ok blockNumber ->
                    ( { model | currentBlockNumber = Just blockNumber, error = Nothing }, Cmd.none )

                Err (Web3.Error error) ->
                    { model | currentBlockNumber = Nothing, error = Just error } ! []

        GetBlockResponse response ->
            case response of
                Ok block ->
                    ( { model | currentBlock = Just block, error = Nothing }, Cmd.none )

                Err (Web3.Error error) ->
                    { model | currentBlock = Nothing, error = Just error } ! []
