module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Web3 exposing (..)
import Json.Decode exposing (Value)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = GetBlockNumber
    | GetBlockNumberResponse Value
    | GetBlock Int
    | GetBlockResponse Value
    | Web3Response Web3.Response


type alias Model =
    { blockNumber : Maybe Int
    , block : Maybe Block
    , web3 : Web3.Model Msg
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { blockNumber = Nothing
    , block = Nothing
    , web3 = Web3.init
    , error = Nothing
    }
        ! []


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text <| viewBlockNumber model ]
        , button [ onClick GetBlockNumber ] [ text "Get Block" ]
        , div [] [ text <| toString model.block ]
        , button [ onClick (GetBlock 4000000) ] [ text "Get Block" ]
        , viewError model
        ]


viewBlockNumber : Model -> String
viewBlockNumber model =
    model.blockNumber |> Maybe.withDefault 0 |> toString


viewError : Model -> Html Msg
viewError model =
    case model.error of
        Nothing ->
            span [] []

        Just err ->
            div [] [ text err ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetBlockNumber ->
            let
                ( web3_, cmd ) =
                    Web3.getBlockNumber model.web3 GetBlockNumberResponse
            in
                { model | web3 = web3_ } ! [ cmd ]

        GetBlockNumberResponse blockNumber_ ->
            case Web3.decodeBlockNumber blockNumber_ of
                Ok blockNumber ->
                    ( { model | blockNumber = Just blockNumber }, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        GetBlock int ->
            let
                ( web3_, cmd ) =
                    Web3.getBlock model.web3 GetBlockResponse int
            in
                { model | web3 = web3_ } ! [ cmd ]

        GetBlockResponse block_ ->
            case Web3.decodeBlock block_ of
                Ok block ->
                    ( { model | block = Just block }, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        Web3Response { id, data } ->
            case Web3.handleResponse model.web3 id of
                Nothing ->
                    { model | error = Just "could get Msg from web3 state" } ! []

                Just msg ->
                    update (msg data) model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Web3.response Web3Response ]
