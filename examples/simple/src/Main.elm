port module Main exposing (..)

import Eth
import Eth.Net as Net exposing (NetworkId(..))
import Eth.Types exposing (..)
import Eth.Sentry.Tx as TxSentry exposing (..)
import Eth.Sentry.Wallet as WalletSentry exposing (WalletSentry)
import Eth.Units exposing (gwei)
import Html exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Value)
import Process
import Task


main : Program Int Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { txSentry : TxSentry Msg
    , account : Maybe Address
    , node : EthNode
    , blockNumber : Maybe Int
    , txHash : Maybe TxHash
    , tx : Maybe Tx
    , txReceipt : Maybe TxReceipt
    , blockDepth : String
    , errors : List String
    }


init : Int -> ( Model, Cmd Msg )
init networkId =
    let
        node =
            Net.toNetworkId networkId
                |> ethNode
    in
        { txSentry = TxSentry.init ( txOut, txIn ) TxSentryMsg node.http
        , account = Nothing
        , node = node
        , blockNumber = Nothing
        , txHash = Nothing
        , tx = Nothing
        , txReceipt = Nothing
        , blockDepth = ""
        , errors = []
        }
            ! [ Task.attempt PollBlock (Eth.getBlockNumber node.http) ]


type alias EthNode =
    { http : HttpProvider
    , ws : WebsocketProvider
    }


ethNode : NetworkId -> EthNode
ethNode networkId =
    case networkId of
        Mainnet ->
            EthNode "https://mainnet.infura.io/" "wss://mainnet.infura.io/ws"

        Ropsten ->
            EthNode "https://ropsten.infura.io/" "wss://ropsten.infura.io/ws"

        Rinkeby ->
            EthNode "https://rinkeby.infura.io/" "wss://rinkeby.infura.io/ws"

        _ ->
            EthNode "UnknownEthNetwork" "UnknownEthNetwork"



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
    | WalletStatus WalletSentry
    | PollBlock (Result Http.Error Int)
    | InitTx
    | WatchTxHash (Result String TxHash)
    | WatchTx (Result String Tx)
    | WatchTxReceipt (Result String TxReceipt)
    | TrackTx TxTracker
    | Fail String
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

        WalletStatus walletSentry ->
            { model
                | account = walletSentry.account
                , node = ethNode walletSentry.networkId
            }
                ! []

        PollBlock (Ok blockNumber) ->
            { model | blockNumber = Just blockNumber }
                ! [ Task.attempt PollBlock <|
                        Task.andThen (\_ -> Eth.getBlockNumber model.node.http) (Process.sleep 1000)
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
                        , onMined = Just ( WatchTxReceipt, Just { confirmations = 3, toMsg = TrackTx } )
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

        Fail str ->
            let
                _ =
                    Debug.log str
            in
                model ! []

        NoOp ->
            model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ walletSentry (WalletSentry.decodeToMsg Fail WalletStatus)
        , TxSentry.listen model.txSentry
        ]



-- Ports


port walletSentry : (Value -> msg) -> Sub msg


port txOut : Value -> Cmd msg


port txIn : (Value -> msg) -> Sub msg
