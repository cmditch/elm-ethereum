module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


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
    ( Model [], Cmd.none )



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
                    Address "0x123123132131231231231231231123"

                watchRequest =
                    LightBox.watchAdd
                        contractAddress
                        { addFilter | address = Just bob }
                        BobAdds
            in
                ( model, Web3.Eth.Event.watch watchRequest )

        AddEvents log ->
            ( log :: model, Cmd.none )

        WatchSubtract ->
            let
                alice =
                    Address "0x42424242424242424242424242424242"
            in
                ( model
                , LightBox.watchSubtract contractAddress
                    { subFilter | address = Just alice }
                    AliceSubtracts
                )

        SubtractEvents log ->
            ( log :: model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ LightBox.sentry BobAdds (decodeAddEvent >> AddEvents)
        , LightBox.sentry AliceSubtracts (decodeSubEvent >> SubtractEvents)
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
