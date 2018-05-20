port module Main exposing (..)

import Eth
import Eth.Decode as Decode
import Eth.Types exposing (..)
import Eth.Sentry.Tx as TxSentry exposing (..)
import Eth.Units exposing (gwei)
import Html exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Value)
import Process
import Task


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { txSentry : TxSentry Msg
    , account : Maybe Address
    , blockNumber : Maybe Int
    , txHash : Maybe TxHash
    , tx : Maybe Tx
    , txReceipt : Maybe TxReceipt
    , blockDepth : String
    , errors : List String
    }


init : ( Model, Cmd Msg )
init =
    { txSentry = TxSentry.init ( txOut, txIn ) TxSentryMsg ethNode
    , account = Nothing
    , blockNumber = Nothing
    , txHash = Nothing
    , tx = Nothing
    , txReceipt = Nothing
    , blockDepth = ""
    , errors = []
    }
        ! [ Task.perform PollBlock (Task.succeed <| Ok 0) ]


ethNode : String
ethNode =
    "https://ropsten.infura.io/"



-- View


view : Model -> Html Msg
view model =
    div []
        [ div []
            (List.map viewThing
                [ ( "Current Block", toString model.blockNumber )
                , ( "--------------------", "" )
                , ( "TxHash", toString model.txHash )
                , ( "--------------------", "" )
                , ( "Tx", toString model.tx )
                , ( "--------------------", "" )
                , ( "TxReceipt", toString model.txReceipt )
                , ( "--------------------", "" )
                , ( "BlockDepth", toString model.blockDepth )
                ]
            )
        , button [ onClick InitTx ] [ text "Send Tx" ]
        , div [] (List.map (\e -> div [] [ text e ]) model.errors)
        ]


viewThing : ( String, String ) -> Html Msg
viewThing ( name, val ) =
    div []
        [ div [] [ text name ]
        , div [] [ text val ]
        ]



-- Update


type Msg
    = TxSentryMsg TxSentry.Msg
    | SetAccount (Maybe Address)
    | PollBlock (Result Http.Error Int)
    | InitTx
    | WatchTxHash (Result String TxHash)
    | WatchTx (Result String Tx)
    | WatchTxReceipt (Result String TxReceipt)
    | TrackTx TxTracker
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TxSentryMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    TxSentry.update subMsg model.txSentry
            in
                ( { model | txSentry = subModel }, subCmd )

        SetAccount mAccount ->
            { model | account = mAccount } ! []

        PollBlock (Ok blockNumber) ->
            { model | blockNumber = Just blockNumber }
                ! [ Task.attempt PollBlock <|
                        Task.andThen (\_ -> Eth.getBlockNumber ethNode) (Process.sleep 1000)
                  ]

        PollBlock (Err error) ->
            model ! []

        InitTx ->
            let
                txParams =
                    { to = model.account
                    , from = model.account
                    , gas = Nothing
                    , gasPrice = Just <| gwei 4
                    , value = Just <| gwei 1
                    , data = Nothing
                    , nonce = Nothing
                    }

                ( newSentry, sentryCmd ) =
                    TxSentry.customSend
                        model.txSentry
                        { onSign = Just WatchTxHash
                        , onBroadcast = Just WatchTx
                        , onMined = Just ( WatchTxReceipt, Just ( 3, TrackTx ) )
                        }
                        txParams
            in
                { model | txSentry = newSentry } ! [ sentryCmd ]

        WatchTxHash (Ok txHash) ->
            { model | txHash = Just txHash } ! []

        WatchTxHash (Err err) ->
            { model | errors = ("Error Retrieving TxHash: " ++ toString err) :: model.errors } ! []

        WatchTx (Ok tx) ->
            { model | tx = Just tx } ! []

        WatchTx (Err err) ->
            { model | errors = ("Error Retrieving Tx: " ++ toString err) :: model.errors } ! []

        WatchTxReceipt (Ok txReceipt) ->
            { model | txReceipt = Just txReceipt } ! []

        WatchTxReceipt (Err err) ->
            { model | errors = ("Error Retrieving TxReceipt: " ++ toString err) :: model.errors } ! []

        TrackTx blockDepth ->
            { model | blockDepth = toString blockDepth } ! []

        NoOp ->
            model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ accountListener accountListenerToMsg
        , TxSentry.listen model.txSentry
        ]


accountListenerToMsg : Value -> Msg
accountListenerToMsg val =
    Decode.decodeValue Decode.address val
        |> Result.toMaybe
        |> SetAccount



-- Ports


port accountListener : (Value -> msg) -> Sub msg


port txOut : Value -> Cmd msg


port txIn : (Value -> msg) -> Sub msg
