module Main exposing (..)

import BigInt
import Element exposing (..)
import Style exposing (StyleSheet)
import Html exposing (Html)


-- Internal

import Eth.Sentry.Event as EventSentry exposing (EventSentry)
import Eth.Types exposing (..)
import Eth
import Eth.Decode as Decode
import Eth.Utils as Utils exposing (functionSig, unsafeToHex)
import Eth.Units exposing (eth, gwei)
import Abi.Encode as Abi
import Task
import Process


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
    , ws = "wss://mainnet.infura.io/ws"
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
    , eventSentry =
        EventSentry.init EventSentryMsg node.ws

    -- |> EventSentry.withDebug
    }
        ! [ Task.perform (\_ -> InitTest) (Task.succeed ()) ]



-- View


view : Model -> Html Msg
view model =
    Element.viewport stylesheet <|
        column NoStyle [] <|
            [ text <|
                toString (List.length model.responses)
                    ++ "/6 tests complete.\n\n"
                    ++ "WatchOnce event test is watching random ERC20 coin's transfer events.\n"
                    ++ "Give it a minute to pick one up.\n\n"
            ]
                ++ (List.map text model.responses)



-- Update


type Msg
    = InitTest
    | WatchOnce
    | NewResponse String
    | EventSentryMsg EventSentry.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitTest ->
            model
                ! [ logCmd
                  , addressCmd
                  , transactionCmd
                  , blockCmd
                  , contractCmds
                  , watchOnceEvent
                  ]

        WatchOnce ->
            let
                ( subModel, subCmd ) =
                    EventSentry.watchOnce (toString >> (++) "WatchOnce Cmd: \n\t" >> NewResponse)
                        model.eventSentry
                        erc20TransferFilter2
            in
                { model | eventSentry = subModel }
                    ! [ subCmd ]

        NewResponse response ->
            { model | responses = response :: model.responses } ! []

        EventSentryMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    EventSentry.update subMsg model.eventSentry
            in
                { model | eventSentry = subModel } ! [ subCmd ]



-- Subs


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ EventSentry.listen model.eventSentry ]



-- Test Cmds


watchOnceEvent : Cmd Msg
watchOnceEvent =
    Task.perform (\_ -> WatchOnce) (Task.succeed ())


logCmd : Cmd Msg
logCmd =
    Eth.getLogs node.http erc20TransferFilter
        |> Task.attempt (toString >> (++) "Log Cmds: \n\t" >> NewResponse)


addressCmd : Cmd Msg
addressCmd =
    Eth.getBalance node.http wrappedEthContract
        |> Task.andThen (\_ -> Eth.getTxCount node.http wrappedEthContract)
        |> Task.andThen (\_ -> Eth.getTxCountAtBlock node.http wrappedEthContract (BlockNum 4620856))
        |> Task.andThen (\_ -> Process.sleep 700)
        |> Task.andThen (\_ -> Eth.getBalanceAtBlock node.http wrappedEthContract (BlockNum 5744072))
        |> Task.map BigInt.toString
        |> Task.attempt (toString >> (++) "Address Cmds: \n\t" >> NewResponse)


transactionCmd : Cmd Msg
transactionCmd =
    Eth.getTx node.http txHash
        |> Task.andThen (.hash >> Eth.getTxReceipt node.http)
        |> Task.andThen
            (\txReceipt ->
                Eth.getTxByBlockHashAndIndex node.http txReceipt.blockHash 0
                    |> Task.andThen (\_ -> Eth.getTxByBlockNumberAndIndex node.http txReceipt.blockNumber 0)
            )
        |> Task.attempt (toString >> (++) "Tx Cmds: \n\t" >> NewResponse)


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
        |> Task.attempt (toString >> (++) "Block Cmds: \n\t" >> NewResponse)


contractCmds : Cmd Msg
contractCmds =
    let
        call =
            { to = Just erc20Contract
            , from = Nothing
            , gas = Just <| 400000
            , gasPrice = Just <| gwei 20
            , value = Nothing
            , data = Just <| Abi.encodeFunctionCall "owner()" []
            , nonce = Nothing
            , decoder = Decode.address
            }
    in
        Eth.callAtBlock node.http call (BlockNum 4620856)
            |> Task.andThen (\_ -> Eth.call node.http call)
            |> Task.andThen (\_ -> Eth.estimateGas node.http call)
            |> Task.andThen (\_ -> Eth.getStorageAt node.http erc20Contract 0)
            |> Task.andThen (\_ -> Eth.getStorageAtBlock node.http erc20Contract 0 (BlockNum 4620856))
            |> Task.andThen (\_ -> Process.sleep 500)
            |> Task.andThen (\_ -> Eth.getCode node.http erc20Contract)
            |> Task.andThen (\_ -> Eth.getCodeAtBlock node.http erc20Contract (BlockNum 4620856))
            |> Task.attempt (toString >> (++) "Contract Cmds: \n\t" >> NewResponse)



-- Data


erc20TransferFilter : LogFilter
erc20TransferFilter =
    { fromBlock = BlockNum 5488303
    , toBlock = BlockNum 5488353
    , address = Utils.unsafeToAddress "0xd850942ef8811f2a866692a623011bde52a462c1"
    , topics = [ Just <| Utils.unsafeToHex "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" ]
    }


erc20TransferFilter2 : LogFilter
erc20TransferFilter2 =
    { fromBlock = LatestBlock
    , toBlock = LatestBlock
    , address = Utils.unsafeToAddress "0xd850942ef8811f2a866692a623011bde52a462c1"
    , topics = [ Just <| Utils.unsafeToHex "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" ]
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



-- Style


type Style
    = NoStyle


stylesheet : StyleSheet Style variations
stylesheet =
    Style.styleSheet [ Style.style NoStyle [] ]
