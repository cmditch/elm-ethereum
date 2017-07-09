module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Web3 exposing (..)


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
    | GetBlockNumberResponse String
    | Web3Response Web3.Response


type alias Model =
    { blockNumber : Maybe String
    , web3 : Web3.Model Msg
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { blockNumber = Nothing
    , web3 = Web3.init
    , error = Nothing
    }
        ! []


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text <| viewBlockNumber model ]
        , button [ onClick GetBlockNumber ] [ text "Get Block" ]
        , viewError model
        ]


viewBlockNumber : Model -> String
viewBlockNumber model =
    model.blockNumber |> Maybe.withDefault "Press button plz"


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

        GetBlockNumberResponse blockNumber ->
            ( { model | blockNumber = Just blockNumber }, Cmd.none )

        Web3Response { id, result } ->
            -- TODO
            -- we know this will be a string at the moment, but will likely need
            -- custom decoders for each function (some results are objects)
            case Web3.handleResponse model.web3 id of
                Nothing ->
                    { model | error = Just "could get Msg from web3 state" } ! []

                Just msg ->
                    update (msg result) model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Web3.response Web3Response ]
