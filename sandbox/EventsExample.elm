module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Web3.Eth.Types exposing (..)
import LightBox exposing (..)
import Web3.Eth.Contract as Contract


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- ""
-- MODEL


type alias Model =
    List String


init : ( Model, Cmd Msg )
init =
    ( [], Cmd.none )



-- UPDATE


type Msg
    = WatchAdd
    | AddEvents (EventLog AddArgs)
    | WatchSubtract
    | SubtractEvents (EventLog SubtractArgs)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WatchAdd ->
            let
                bob =
                    Address "0x12312313213123123123123123112323"
            in
                ( model
                , LightBox.add_
                    contractAddress
                    { addFilter | mathematician = Just [ bob ] }
                    "bobAdds"
                )

        AddEvents log ->
            ( log :: model, Cmd.none )

        WatchSubtract ->
            let
                alice =
                    Address "0x42424242424242424242424242424242"
            in
                ( model
                , LightBox.subtract_
                    contractAddress
                    { subFilter | professor = Just [ alice ] }
                    "aliceSubtracts"
                )

        SubtractEvents log ->
            ( log :: model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Contract.sentry "bobAdds" (decodeAddEvent >> AddEvents)
        , Contract.sentry "aliceSubtracts" (decodeSubEvent >> SubtractEvents)
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [] (List.map viewMessage model.messages)
        , button [ onClick Send ] [ text "Watch For Event" ]
        ]


viewMessage : String -> Html msg
viewMessage msg =
    div []
        [ text msg ]
