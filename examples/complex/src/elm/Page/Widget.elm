module Page.Widget exposing (Model, Msg, init, update, view)

-- Library

import BigInt exposing (BigInt)
import Eth as Eth
import Eth.Types exposing (..)
import Eth.Utils as EthUtils
import Eth.Sentry.ChainCmd as ChainCmd exposing (ChainCmd)
import Eth.Units exposing (gwei)
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (onClick)
import Task
import Http


--Internal

import Request.Status exposing (RemoteData(..))
import Contracts.WidgetFactory as Widget exposing (Widget)
import Data.Chain as ChainData exposing (NodePath)
import Views.Styles exposing (Styles(..), Variations(..))


type alias Model =
    { widgetId : BigInt
    , widget : RemoteData Http.Error Widget
    , widgetSellPending : RemoteData String ()
    , errors : List String
    }


init : NodePath -> BigInt -> ( Model, Cmd Msg )
init nodePath widgetId =
    { widgetId = widgetId
    , widget = Loading
    , widgetSellPending = NotAsked
    , errors = []
    }
        ! [ Eth.call nodePath.http (Widget.widgets ChainData.widgetFactory widgetId)
                |> Task.attempt WidgetInfo
          ]



-- VIEW


view : Maybe Address -> Model -> Element Styles Variations Msg
view mAccount model =
    let
        loadingView strMsg =
            row None
                [ width fill, height fill, center, verticalCenter ]
                [ column None
                    [ center, paddingTop 20, moveDown 70 ]
                    [ text strMsg
                    , decorativeImage None [ width (percent 30), center, paddingTop 15 ] { src = "static/img/loader.gif" }
                    ]
                ]
    in
        case ( mAccount, model.widget ) of
            ( Nothing, _ ) ->
                text "Log into metamask please"

            ( _, NotAsked ) ->
                loadingView "Loading Widget"

            ( _, Loading ) ->
                loadingView "Loading Widget"

            ( _, Failure e ) ->
                text <| "Error loading widget data\n" ++ toString e

            ( Just account, Success w ) ->
                row None
                    [ width fill, height fill, center, verticalCenter ]
                    [ column WidgetText
                        [ spacing 5 ]
                        [ text <| "Id : " ++ BigInt.toString w.id
                        , text <| "Size : " ++ BigInt.toString w.size
                        , text <| "Cost : " ++ BigInt.toString w.cost
                        , text <| "Owner : " ++ EthUtils.addressToString w.owner
                        , text <| "Sold : " ++ toString w.wasSold
                        , when (not w.wasSold) <|
                            case model.widgetSellPending of
                                NotAsked ->
                                    button Button [ width (px 100), moveDown 10, onClick (Sell w.id) ] (text "Sell Me")

                                Loading ->
                                    loadingView "Selling Widget"

                                Failure _ ->
                                    text "Error selling"

                                Success _ ->
                                    text "Sold!"
                        ]
                    ]



-- UPDATE


type Msg
    = NoOp
    | WidgetInfo (Result Http.Error Widget)
    | Sell BigInt
    | SellPending (Result String Tx)
    | Sold (Result String TxReceipt)
    | Fail String


update : NodePath -> Msg -> Model -> ( Model, Cmd Msg, ChainCmd Msg )
update nodePath msg model =
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            , ChainCmd.none
            )

        WidgetInfo (Ok widget) ->
            ( { model | widget = Success widget }
            , Cmd.none
            , ChainCmd.none
            )

        WidgetInfo (Err err) ->
            ( { model | widget = Failure err }
            , Cmd.none
            , ChainCmd.none
            )

        Sell id ->
            let
                txParams =
                    Widget.sellWidget ChainData.widgetFactory id
                        |> (\txp -> { txp | gasPrice = Just <| gwei 20 })
                        |> Eth.toSend
            in
                ( model
                , Cmd.none
                , ChainCmd.sendWithReceipt SellPending Sold txParams
                )

        SellPending (Ok _) ->
            ( { model | widgetSellPending = Loading }
            , Cmd.none
            , ChainCmd.none
            )

        SellPending (Err err) ->
            ( { model | widgetSellPending = Failure err }
            , Cmd.none
            , ChainCmd.none
            )

        Sold (Ok _) ->
            ( { model | widgetSellPending = Success () }
            , Cmd.none
            , ChainCmd.none
            )

        Sold (Err err) ->
            ( { model | widgetSellPending = Failure err }
            , Cmd.none
            , ChainCmd.none
            )

        Fail error ->
            ( { model | errors = toString error :: model.errors }
            , Cmd.none
            , ChainCmd.none
            )
