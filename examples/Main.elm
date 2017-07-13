module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (value)
import Html.Events exposing (onClick, onInput)
import Web3 exposing (..)
import Web3.Eth exposing (getBlockNumber, getBlock, decodeBlockNumber)
import Web3.Eth.Types exposing (Block)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { currentBlockNumber : Maybe Int
    , blockNumTextField : String
    , block : Maybe Block
    , web3 : Web3.Model Msg
    , error : Maybe String
    }


init : ( Model, Cmd Msg )
init =
    { currentBlockNumber = Nothing
    , blockNumTextField = ""
    , block = Nothing
    , web3 = Web3.init
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
        , viewBlock model.block
        , button [ onClick (GetBlock <| stringToMaybeInt model.blockNumTextField) ] [ text "Get Block" ]
        , input [ onInput SetBlockNumInput, value model.blockNumTextField ] []
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
    = SetBlockNumInput String
    | GetBlockNumber
    | GetBlockNumberResponse String
    | GetBlock (Maybe Int)
    | GetBlockResponse String
    | Web3Response Web3.Response


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetBlockNumInput blockNum ->
            { model | blockNumTextField = blockNum } ! []

        GetBlockNumber ->
            let
                ( web3_, cmd ) =
                    Web3.Eth.getBlockNumber model.web3 GetBlockNumberResponse
            in
                { model | web3 = web3_ } ! [ cmd ]

        GetBlockNumberResponse blockNumber_ ->
            case Web3.Eth.decodeBlockNumber blockNumber_ of
                Ok blockNumber ->
                    ( { model | currentBlockNumber = Just blockNumber, error = Nothing }, Cmd.none )

                Err error ->
                    ( { model | error = Just error }, Cmd.none )

        GetBlock int ->
            case int of
                Nothing ->
                    { model | error = Just "Block number invalid" } ! []

                Just int_ ->
                    let
                        ( web3_, cmd ) =
                            Web3.Eth.getBlock model.web3 GetBlockResponse int_
                    in
                        { model | web3 = web3_ } ! [ cmd ]

        GetBlockResponse block_ ->
            case Web3.Eth.decodeBlock block_ of
                Ok block ->
                    ( { model | block = Just block, error = Nothing }, Cmd.none )

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
