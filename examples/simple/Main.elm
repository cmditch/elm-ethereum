port module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Value)
import Process
import Task
import Web3.Eth as Eth
import Web3.Eth.Decode as Decode
import Web3.Eth.Types exposing (..)
import Web3.Eth.TxSentry as TxSentry exposing (..)
import Web3.Utils exposing (gwei, unsafeToAddress)


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
    , tx : Maybe Tx
    , txReceipt : Maybe TxReceipt
    , blockDepth : BlockDepth
    , errors : List String
    }


init : ( Model, Cmd Msg )
init =
    { txSentry = TxSentry.init ( txOut, txIn ) TxSentryMsg ethNode
    , account = Nothing
    , blockNumber = Nothing
    , tx = Nothing
    , txReceipt = Nothing
    , blockDepth = Unmined
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
                , ( "Tx", toString model.tx )
                , ( "--------------------", "" )
                , ( "TxReceipt", toString model.txReceipt )
                , ( "--------------------", "" )
                , ( "BlockDepth", toString model.blockDepth )
                ]
            )
        , button [ onClick InitTx ] [ text "Send Tx" ]
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
    | WatchTx Tx
    | WatchTxReceipt TxReceipt
    | WatchTxBlockDepth BlockDepth
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

        PollBlock blockNumber ->
            { model | blockNumber = Result.toMaybe blockNumber }
                ! [ Task.attempt PollBlock <|
                        Task.andThen (\_ -> Eth.getBlockNumber ethNode) (Process.sleep 1000)
                  ]

        InitTx ->
            case model.account of
                Just account ->
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
                                { onSign = Nothing
                                , onBroadcast = Just WatchTx
                                , onMined = Just ( WatchTxReceipt, Just ( 5, WatchTxBlockDepth ) )
                                }
                                txParams
                                model.txSentry
                    in
                        { model | txSentry = newSentry } ! [ sentryCmd ]

                Nothing ->
                    model ! []

        WatchTx tx ->
            { model | tx = Just tx } ! []

        WatchTxReceipt txReceipt ->
            { model | txReceipt = Just txReceipt } ! []

        WatchTxBlockDepth blockDepth ->
            { model | blockDepth = blockDepth } ! []

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
