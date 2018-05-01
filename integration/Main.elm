module Main exposing (..)

import Element exposing (..)
import Style exposing (StyleSheet)
import Html exposing (Html)


-- Internal

import Task
import Process
import Web3.Eth.EventSentry as EventSentry exposing (EventSentry)
import Web3.Eth.Types exposing (..)
import Web3.Eth as Eth
import Web3.Eth.Decode as Decode
import Web3.Utils as Utils exposing (eth, gwei, functionSig, unsafeToHex)


-- Program


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


node =
    { http = "https://mainnet.infura.io/metamask"
    , ws = "ws://ec2-52-42-145-83.us-west-2.compute.amazonaws.com:8546"
    }



-- Model


type alias Model =
    { responses : List String
    , pendingTxHashes : List TxHash
    , eventSentry : EventSentry Msg
    }


init : ( Model, Cmd Msg )
init =
    { responses = []
    , pendingTxHashes = []
    , eventSentry = EventSentry.init node.ws |> EventSentry.withDebug
    }
        ! [ Task.perform (\_ -> InitTest) (Task.succeed ()) ]



-- View


view : Model -> Html Msg
view model =
    Element.viewport stylesheet <|
        column "" [] (List.map text model.responses)



-- Update


type Msg
    = NoOp
    | InitTest
    | EventSentryMsg (EventSentry.Msg Msg)
    | PendingTx TxHash
    | NewResponse String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        InitTest ->
            let
                ( sentryModel, sentryCmd ) =
                    EventSentry.pendingTxs (toString >> NewResponse) model.eventSentry
            in
                { model | eventSentry = sentryModel }
                    ! [ Cmd.map EventSentryMsg sentryCmd ]

        --blockCmd, contractCmds, transactionCmd, addressCmd, logCmd, ]
        EventSentryMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    EventSentry.update subMsg model.eventSentry
            in
                { model | eventSentry = subModel } ! [ Cmd.map EventSentryMsg subCmd ]

        PendingTx txHash ->
            { model | pendingTxHashes = txHash :: model.pendingTxHashes }
                ! []

        NewResponse response ->
            { model | responses = response :: model.responses } ! []



-- Data


erc20TransferFilter : LogFilter
erc20TransferFilter =
    { fromBlock = BlockIdNum 5488303
    , toBlock = LatestBlock
    , address = Utils.unsafeToAddress "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C"
    , topics = [ Just "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" ]
    }


erc20Contract : Address
erc20Contract =
    Utils.unsafeToAddress "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2"


wrappedEthContract : Address
wrappedEthContract =
    Utils.unsafeToAddress "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"


txHash : TxHash
txHash =
    Utils.unsafeToTxHash "0x5c9b0f9c6c32d2690771169ec62dd648fef7bce3d45fe8a6505d99fdcbade27a"


blockHash : BlockHash
blockHash =
    Utils.unsafeToBlockHash "0x4f4b2cedbf641cf7213ea9612ed549ed39732ce3eb640500ca813af41ab16cd1"



-- Test Cmds


logCmd : Cmd Msg
logCmd =
    Eth.getLogs node.http erc20TransferFilter
        |> Task.attempt (toString >> NewResponse)


addressCmd : Cmd Msg
addressCmd =
    Eth.getBalance node.http wrappedEthContract
        |> Task.andThen (\_ -> Eth.getBalanceAtBlock node.http (BlockIdNum 4620856) wrappedEthContract)
        |> Task.andThen (\_ -> Process.sleep 700)
        |> Task.andThen (\_ -> Eth.getTxCount node.http wrappedEthContract)
        |> Task.andThen (\_ -> Eth.getTxCountAtBlock node.http (BlockIdNum 4620856) wrappedEthContract)
        |> Task.attempt (toString >> NewResponse)


transactionCmd : Cmd Msg
transactionCmd =
    Eth.getTx node.http txHash
        |> Task.andThen (.hash >> Eth.getTxReceipt node.http)
        |> Task.andThen
            (\txReceipt ->
                Eth.getTxByBlockHashAndIndex node.http txReceipt.blockHash 0
                    |> Task.andThen (\_ -> Eth.getTxByBlockNumberAndIndex node.http txReceipt.blockNumber 0)
            )
        |> Task.attempt (toString >> NewResponse)


blockCmd : Cmd Msg
blockCmd =
    Eth.getBlockNumber node.http
        |> Task.andThen (Eth.getBlock node.http)
        |> Task.andThen (\block -> Eth.getBlockByHash node.http block.hash)
        |> Task.andThen (\block -> Eth.getBlockWithTxObjs node.http 5487588)
        |> Task.andThen (\block -> Eth.getBlockByHashWithTxObjs node.http block.hash)
        |> Task.andThen
            (\block ->
                Eth.getBlockTxCount node.http block.number
                    |> Task.andThen (\_ -> Process.sleep 500)
                    |> Task.andThen (\_ -> Eth.getBlockTxCountByHash node.http block.hash)
                    |> Task.andThen (\_ -> Eth.getUncleCount node.http block.number)
                    |> Task.andThen (\_ -> Eth.getUncleCountByHash node.http block.hash)
                    |> Task.andThen (\_ -> Eth.getUncleAtIndex node.http block.number 0)
                    |> Task.andThen (\_ -> Process.sleep 500)
                    |> Task.andThen (\_ -> Eth.getUncleByBlockHashAtIndex node.http block.hash 0)
            )
        |> Task.attempt (toString >> NewResponse)


contractCmds : Cmd Msg
contractCmds =
    let
        call =
            { to = Just erc20Contract
            , from = Nothing
            , gas = Just <| 400000
            , gasPrice = Just <| gwei 20
            , value = Nothing
            , data = Just <| unsafeToHex <| functionSig "owner()"
            , nonce = Nothing
            , decoder = Decode.address
            }
    in
        Eth.callAtBlock node.http (BlockIdNum 4620856) call
            |> Task.andThen (\_ -> Eth.call node.http call)
            |> Task.andThen (\_ -> Eth.estimateGas node.http call)
            |> Task.andThen (\_ -> Eth.getStorageAt node.http erc20Contract 0)
            |> Task.andThen (\_ -> Eth.getStorageAtBlock node.http (BlockIdNum 4620856) erc20Contract 0)
            |> Task.andThen (\_ -> Process.sleep 500)
            |> Task.andThen (\_ -> Eth.getCode node.http erc20Contract)
            |> Task.andThen (\_ -> Eth.getCodeAtBlock node.http (BlockIdNum 4620856) erc20Contract)
            |> Task.attempt (toString >> NewResponse)



-- Subs


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ EventSentry.listen model.eventSentry EventSentryMsg ]



-- Style


stylesheet : StyleSheet String variations
stylesheet =
    Style.styleSheet [ Style.style "" [] ]
