module Main exposing (main)

-- Internal

import Abi.Encode
import BigInt
import Browser
import Eth
import Eth.Decode as Decode
import Eth.Sentry.Event as EventSentry exposing (EventSentry)
import Eth.Types exposing (..)
import Eth.Units exposing (eth, gwei)
import Eth.Utils as Utils exposing (functionSig, unsafeToHex)
import Html exposing (Html, div, text)
import Http
import Process
import String.Conversions
import Task



-- Program


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


ethNode =
    "https://mainnet.infura.io/v3/f04200fc1dd4419aa93210e3f799adbf"



-- Model


type alias Model =
    { responses : List String
    , pendingTxHashes : List TxHash
    , eventSentry : EventSentry Msg
    }


init : ( Model, Cmd Msg )
init =
    let
        ( esModel, esCmds ) =
            EventSentry.init EventSentryMsg ethNode
    in
    ( { responses = []
      , pendingTxHashes = []
      , eventSentry = esModel
      }
    , Cmd.batch [ Task.perform (\_ -> InitTest) (Task.succeed ()), esCmds ]
    )



-- View


view : Model -> Html Msg
view model =
    let
        br =
            Html.br [] []

        header =
            [ String.fromInt (List.length model.responses)
                ++ "/8 tests complete (Continous watching will keep adding \"successes\")."
            , "EventSentry tests are watching for DAI ERC20 transfer events."
            , "Give it a minute to pick one up."
            , ""
            ]
                |> List.map text
                |> List.intersperse br

        testData =
            List.intersperse "" model.responses
                |> List.map text
                |> List.intersperse br
    in
    div [] (header ++ [ br, br ] ++ testData)



-- Update


type Msg
    = InitTest
    | WatchLatest
    | WatchRanged
    | WatchOnceRangeToLatest
    | NewResponse String
    | EventSentryMsg EventSentry.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitTest ->
            ( model
            , Cmd.batch
                [ logCmd
                , addressCmd
                , transactionCmd
                , blockCmd
                , contractCmds
                , watchLatest
                , watchRanged
                , watchOnceRangeToLatest
                ]
            )

        WatchLatest ->
            let
                ( subModel, subCmd, _ ) =
                    EventSentry.watch watchLatestHelper
                        model.eventSentry
                        filterLatest
            in
            ( { model | eventSentry = subModel }, subCmd )

        WatchRanged ->
            let
                ( subModel, subCmd, _ ) =
                    EventSentry.watch watchRangedHelper
                        model.eventSentry
                        filterRanged
            in
            ( { model | eventSentry = subModel }, subCmd )

        WatchOnceRangeToLatest ->
            let
                ( subModel, subCmd ) =
                    EventSentry.watchOnce watchOnceRangeToLatestHelper
                        model.eventSentry
                        filterRangeToLatest
            in
            ( { model | eventSentry = subModel }, subCmd )

        NewResponse response ->
            ( { model | responses = response :: model.responses }, Cmd.none )

        EventSentryMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    EventSentry.update subMsg model.eventSentry
            in
            ( { model | eventSentry = subModel }, subCmd )



-- Test Cmds


logCmd : Cmd Msg
logCmd =
    Eth.getLogs ethNode erc20TransferFilter
        |> Task.attempt
            (responseToString
                (List.map logToString >> String.join ", " >> (++) "Log Cmds: ")
                >> NewResponse
            )


addressCmd : Cmd Msg
addressCmd =
    Eth.getBalance ethNode wrappedEthContract
        |> Task.andThen (\_ -> Eth.getTxCount ethNode wrappedEthContract)
        |> Task.andThen (\_ -> Eth.getTxCountAtBlock ethNode wrappedEthContract (BlockNum 4620856))
        |> Task.andThen (\_ -> Process.sleep 700)
        |> Task.andThen (\_ -> Eth.getBalanceAtBlock ethNode wrappedEthContract (BlockNum 5744072))
        |> Task.map BigInt.toString
        |> Task.attempt
            (responseToString
                ((++) "Address Cmds: ")
                >> NewResponse
            )


transactionCmd : Cmd Msg
transactionCmd =
    Eth.getTx ethNode txHash
        |> Task.andThen (.hash >> Eth.getTxReceipt ethNode)
        |> Task.andThen
            (\txReceipt ->
                Eth.getTxByBlockHashAndIndex ethNode txReceipt.blockHash 0
                    |> Task.andThen (\_ -> Eth.getTxByBlockNumberAndIndex ethNode txReceipt.blockNumber 0)
            )
        |> Task.attempt
            (responseToString
                (.hash >> Utils.txHashToString >> (++) "Tx Cmds: ")
                >> NewResponse
            )


blockCmd : Cmd Msg
blockCmd =
    Eth.getBlockNumber ethNode
        |> Task.andThen (Eth.getBlock ethNode)
        |> Task.andThen (\block -> Eth.getBlockByHash ethNode block.hash)
        |> Task.andThen (\block -> Eth.getBlockWithTxObjs ethNode 5487588)
        |> Task.andThen (\block -> Eth.getBlockByHashWithTxObjs ethNode block.hash)
        |> Task.andThen
            (\block ->
                Eth.getBlockTxCount ethNode block.number
                    |> Task.andThen (\_ -> Process.sleep 500)
                    |> Task.andThen (\_ -> Eth.getBlockTxCountByHash ethNode block.hash)
                    |> Task.andThen (\_ -> Eth.getUncleCount ethNode block.number)
                    |> Task.andThen (\_ -> Eth.getUncleCountByHash ethNode block.hash)
                    |> Task.andThen (\_ -> Eth.getUncleAtIndex ethNode block.number 0)
                    |> Task.andThen (\_ -> Process.sleep 500)
                    |> Task.andThen (\_ -> Eth.getUncleByBlockHashAtIndex ethNode block.hash 0)
            )
        |> Task.attempt
            (responseToString
                (.hash >> Utils.blockHashToString >> (++) "Block Cmds: ")
                >> NewResponse
            )


contractCmds : Cmd Msg
contractCmds =
    let
        call =
            { to = Just erc20Contract
            , from = Nothing
            , gas = Just <| 400000
            , gasPrice = Just <| gwei 20
            , value = Nothing
            , data = Just <| Abi.Encode.functionCall "owner()" []
            , nonce = Nothing
            , decoder = Decode.address
            }
    in
    Eth.callAtBlock ethNode call (BlockNum 4620856)
        |> Task.andThen (\_ -> Eth.call ethNode call)
        |> Task.andThen (\_ -> Eth.estimateGas ethNode call)
        |> Task.andThen (\_ -> Eth.getStorageAt ethNode erc20Contract 0)
        |> Task.andThen (\_ -> Eth.getStorageAtBlock ethNode erc20Contract 0 (BlockNum 4620856))
        |> Task.andThen (\_ -> Process.sleep 500)
        |> Task.andThen (\_ -> Eth.getCode ethNode erc20Contract)
        |> Task.andThen (\_ -> Eth.getCodeAtBlock ethNode erc20Contract (BlockNum 4620856))
        |> Task.attempt
            (responseToString
                ((++) "Contract Cmds: \n\t")
                >> NewResponse
            )



-- Data


erc20TransferFilter : LogFilter
erc20TransferFilter =
    { fromBlock = BlockNum 5488303
    , toBlock = BlockNum 5488353
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


logToString : Log -> String
logToString log =
    Utils.txHashToString log.transactionHash


responseToString : (a -> String) -> Result Http.Error a -> String
responseToString okToString result =
    case result of
        Ok res ->
            okToString res

        Err err ->
            String.Conversions.fromHttpError err



-- EventSentry Helpers
-- ( Using DAI transfer event )


watchLatest : Cmd Msg
watchLatest =
    Task.perform (\_ -> WatchLatest) (Task.succeed ())


watchLatestHelper =
    logToString >> (++) "WatchLatest Cmd: " >> NewResponse


filterLatest : LogFilter
filterLatest =
    { fromBlock = LatestBlock
    , toBlock = LatestBlock
    , address = Utils.unsafeToAddress "0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359"
    , topics = [ Just <| Utils.unsafeToHex "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" ]
    }



--


watchRanged : Cmd Msg
watchRanged =
    Task.perform (\_ -> WatchRanged) (Task.succeed ())


watchRangedHelper =
    logToString >> (++) "WatchRanged Cmd: " >> NewResponse


filterRanged : LogFilter
filterRanged =
    { filterLatest
        | fromBlock = BlockNum 7396400
        , toBlock = BlockNum 7396404
    }



--


watchOnceRangeToLatest : Cmd Msg
watchOnceRangeToLatest =
    Task.perform (\_ -> WatchOnceRangeToLatest) (Task.succeed ())


watchOnceRangeToLatestHelper =
    logToString >> (++) "WatchOnceRangeToLatest Cmd: " >> NewResponse


filterRangeToLatest : LogFilter
filterRangeToLatest =
    { filterLatest
        | fromBlock = BlockNum 7396400
        , toBlock = LatestBlock
    }
