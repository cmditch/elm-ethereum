module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Web3.Eth.Types exposing (..)
import LightBox exposing (..)
import Web3.Eth.Contract as Contract
import Web3.Eth.Event as Event exposing (..)


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    List String


init : ( Model, Cmd Msg )
init =
    ( [], Cmd.none )



-- UPDATE


type Msg
    = WatchAdd
    | AddEvents String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WatchAdd ->
            let
                bob =
                    Address "0xeb8f5983d099b0be3f78367bf5efccb5df9e3487"
            in
                ( model
                , LightBox.add_
                    bob
                    addFilter
                    "bobAdds"
                )

        AddEvents log ->
            (log :: model) ! []



-- WatchSubtract ->
--     let
--         alice =
--             Address "0x42424242424242424242424242424242"
--     in
--         ( model
--         , LightBox.subtract_
--             contractAddress
--             { subFilter | professor = Just [ alice ] }
--             "aliceSubtracts"
--         )
--
-- SubtractEvents log ->
--     ( log :: model, Cmd.none )
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Event.sentry "bobAdds" AddEvents ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [] (List.map viewMessage model)
        , button [ onClick WatchAdd ] [ text "Watch For Event" ]
        ]


viewMessage : String -> Html msg
viewMessage msg =
    div []
        [ text msg ]
