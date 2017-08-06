module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Web3.Eth.Types exposing (..)
import LightBox exposing (..)
import Web3.Eth.Event as Event exposing (..)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { log : List String
    , funLog : List String
    , isWatchingAdd : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( Model [] [] False, Cmd.none )



-- UPDATE


type Msg
    = WatchAdd
    | StopWatchingAdd
    | Reset
    | AddEvents String
    | AddEventsAgainForFun String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WatchAdd ->
            let
                bob =
                    Address "0xeb8f5983d099b0be3f78367bf5efccb5df9e3487"
            in
                { model | isWatchingAdd = True }
                    ! [ LightBox.add_ bob addFilter "bobAdds"
                      , LightBox.add_ bob addFilter "caraAdds"
                      ]

        StopWatchingAdd ->
            { model | isWatchingAdd = False } ! [ Event.stopWatching "bobAdds" ]

        Reset ->
            { model | isWatchingAdd = False } ! [ Event.reset ]

        AddEvents log ->
            { model | log = log :: model.log } ! []

        AddEventsAgainForFun log ->
            { model | funLog = String.reverse log :: model.funLog } ! []



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
        [ Event.sentry "bobAdds" AddEvents
        , Event.sentry "caraAdds" AddEventsAgainForFun
        , Event.sentry "nullTest" AddEvents
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text "Logs from AddEvents" ]
        , div [] (List.map viewMessage model.log)
        , div [] [ br [] [], br [] [] ]
        , div [] [ text "Logs from AddEventsAgainForFun" ]
        , div [] (List.map viewMessage model.funLog)
        , div [] [ br [] [], br [] [] ]
        , viewButton model
        , button [ onClick Reset ] [ text "Reset all events" ]
        ]


viewMessage : String -> Html Msg
viewMessage msg =
    div []
        [ text msg ]


viewButton : Model -> Html Msg
viewButton model =
    case model.isWatchingAdd of
        False ->
            button [ onClick WatchAdd ] [ text "Watch For Event" ]

        True ->
            button [ onClick StopWatchingAdd ] [ text "Stop Watching the Event" ]
