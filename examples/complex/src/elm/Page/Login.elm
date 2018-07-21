module Page.Login exposing (Model, Msg(LoggedIn, SkipLogin), init, update, view, subscriptions)

--Library

import Animation
import Element exposing (..)
import Element.Events exposing (..)
import Element.Attributes exposing (..)
import Eth.Types exposing (Address)
import Html
import Html.Attributes
import Process
import WebSocket


--Internal

import Views.Styles exposing (Styles(..), Variations(..))
import Task
import Time
import Request.UPort as UPort


type alias Model =
    { errors : List String
    , animationPage : Animation.State
    , loginRequested : Bool
    , loginRequest : Maybe UPort.RequestData
    , loginSuccess : Bool
    }


init : ( Model, Cmd Msg )
init =
    { errors = []
    , animationPage = Animation.style [ Animation.opacity 0.0 ]
    , loginRequested = False
    , loginRequest = Nothing
    , loginSuccess = False
    }
        ! [ Task.perform StartAnimation (Task.succeed ()) ]


view : Maybe Address -> Model -> Element Styles Variations Msg
view mAccount model =
    column LoginPage
        (List.concat
            [ List.map toAttr <| Animation.render model.animationPage
            , [ width fill, height fill, center, verticalCenter ]
            ]
        )
        [ (when << not) model.loginRequested <|
            column None
                [ spacing 20, verticalCenter, center, height fill ]
                [ decorativeImage None
                    [ width <| px 400 ]
                    { src = "static/img/elm-ethereum-logo.svg" }
                , el Header
                    [ vary H2 True
                    , vary Bold True
                    , vary WidgetWhite True
                    ]
                    (text "elm-ethereum example")
                , case mAccount of
                    Nothing ->
                        column LoginBox
                            [ padding 20 ]
                            [ el Header [ vary H4 True, vary WidgetWhite True ] <| text "Please Unlock Metamask" ]

                    Just _ ->
                        column None
                            [ spacing 90 ]
                            [ row LoginBox
                                [ width (px 250)
                                , padding 10
                                , spacing 15
                                , center
                                , verticalCenter
                                , onClick Login
                                ]
                                [ viewUPortLogo 40
                                , text "Sign in with uPort"
                                ]
                            , button LoginBox
                                [ onClick SkipLogin, width (px 100), center ]
                                (text "Skip")
                            ]
                ]
        , whenJust model.loginRequest <|
            (\request ->
                column LoginBox
                    [ center, verticalCenter, padding 20, spacing 20 ]
                    [ viewUPortLogo 60
                    , text "Scan with the uPort app"
                    , image None [ width (px 400) ] { src = request.qr, caption = request.uri }
                    , (when << not) model.loginSuccess <|
                        row None
                            [ spacing 10, verticalCenter ]
                            [ image None
                                [ width (px 35), height (px 35) ]
                                { src = "static/img/loader.gif", caption = "loading..." }
                            , text "Waiting for response from uPort..."
                            ]
                    , when model.loginSuccess <|
                        row None
                            [ spacing 10, verticalCenter ]
                            [ el WidgetText [ vary WidgetBlue True ] <|
                                html <|
                                    Html.i [ Html.Attributes.class "far fa-check-circle" ] []
                            , text "Success!"
                            ]
                    ]
            )
        ]


viewUPortLogo : Float -> Element Styles Variations Msg
viewUPortLogo dim =
    image None
        [ width <| px dim, height <| px dim ]
        { src = "static/img/uport.png", caption = "uPort Logo" }


type Msg
    = NoOp
    | Login
    | SkipLogin
    | PollWSConnection Int
    | LoggedIn UPort.User
    | UPortMessage UPort.Message
    | Animate Animation.Msg
    | StartAnimation ()


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        LoggedIn _ ->
            -- captured in parent module
            model ! []

        Login ->
            { model | loginRequested = True }
                ! [ WebSocket.send UPort.authEndpoint "login"
                  , Task.perform PollWSConnection (Task.succeed 20)
                  ]

        SkipLogin ->
            { model | loginRequested = True } ! []

        PollWSConnection times ->
            if model.loginRequested && times > 0 then
                model
                    ! [ WebSocket.send UPort.authEndpoint "keepalive"
                      , Task.perform (\_ -> PollWSConnection <| times - 1) (Process.sleep 15000)
                      ]
            else
                model ! []

        UPortMessage message ->
            case message of
                UPort.Request r ->
                    { model | loginRequest = Just r } ! []

                UPort.Success s ->
                    { model | loginSuccess = True }
                        ! [ Task.perform LoggedIn
                                -- delay signal for a moment to swap out loading gif
                                (Process.sleep Time.second |> Task.andThen (\() -> Task.succeed s.user))
                          ]

                UPort.Error e ->
                    let
                        _ =
                            Debug.log "uport error" e
                    in
                        model ! []

        Animate aMsg ->
            { model | animationPage = Animation.update aMsg model.animationPage } ! []

        StartAnimation () ->
            { model
                | animationPage =
                    Animation.interrupt
                        [ Animation.wait (0.5 * Time.second)
                        , Animation.toWith (Animation.easing { duration = Time.second, ease = identity })
                            [ Animation.opacity 1.0 ]
                        ]
                        model.animationPage
            }
                ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Animation.subscription Animate [ model.animationPage ]
        , if model.loginRequested then
            WebSocket.listen UPort.authEndpoint (UPort.decodeMessage UPortMessage)
          else
            Sub.none
        ]
