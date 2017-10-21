module Pages.Eth exposing (..)

import Element exposing (..)
import Config exposing (..)
import Dict exposing (Dict)
import Task exposing (Task)
import BigInt exposing (BigInt)
import Web3.Types exposing (..)
import Web3.Eth
import Element.Attributes exposing (..)
import Element.Events exposing (onClick)


init : Model
init =
    { tests = Nothing
    , error = Nothing
    }


type alias Model =
    { tests : Maybe (Dict.Dict Int Test)
    , error : Maybe Error
    }


testCommands : Config -> List (Cmd Msg)
testCommands config =
    [ Task.attempt (GetProtocolVersion "getProtocolVersion") (Web3.Eth.getProtocolVersion)
    , Task.attempt (IsSyncing "isSyncing") (Web3.Eth.isSyncing)
    , Task.attempt (GetCoinbase "getCoinbase") (Web3.Eth.getCoinbase)
    , Task.attempt (IsMining "isMining") (Web3.Eth.isMining)
    , Task.attempt (GetHashrate "getHashrate") (Web3.Eth.getHashrate)
    , Task.attempt (GetGasPrice "getGasPrice") (Web3.Eth.getGasPrice)
    , Task.attempt (GetAccounts "getAccounts") (Web3.Eth.getAccounts)
    , Task.attempt (GetBlockNumber "getBlockNumber") (Web3.Eth.getBlockNumber)
    , Task.attempt (GetBalance "getBalance") (Web3.Eth.getBalance config.account)
    , Task.attempt (GetStorageAt "getStorageAt") (Web3.Eth.getStorageAt config.contract 1)
    , Task.attempt (GetStorageAtBlock "getStorageAtBlock") (Web3.Eth.getStorageAtBlock config.blockNumber config.contract 1)
    , Task.attempt (GetCode "getCode") (Web3.Eth.getCode config.contract)
    , Task.attempt (GetCodeAtBlock "getCodeAtBlock") (Web3.Eth.getCodeAtBlock config.blockNumber config.contract)
    , Task.attempt (GetBlockTransactionCount "getBlockTransactionCount") (Web3.Eth.getBlockTransactionCount config.blockNumber)
    , Task.attempt (GetBlock "getBlock") (Web3.Eth.getBlock config.blockNumber)
    , Task.attempt (GetBlockTxObjs "getBlockTxObjs") (Web3.Eth.getBlockTxObjs config.blockNumber)
    , Task.attempt (GetBlockUncleCount "getBlockUncleCount") (Web3.Eth.getBlockUncleCount config.blockNumber)
    , Task.attempt (GetUncle "getUncle") (Web3.Eth.getUncle config.blockNumber 0)
    , Task.attempt (GetUncleTxObjs "getUncleTxObjs") (Web3.Eth.getUncleTxObjs config.blockNumber 0)
    , Task.attempt (GetTransaction "getTransaction") (Web3.Eth.getTransaction config.txId)
    , Task.attempt (GetTransactionFromBlock "getTransactionFromBlock") (Web3.Eth.getTransactionFromBlock config.blockNumber 1)
    , Task.attempt (GetTransactionReceipt "getTransactionReceipt") (Web3.Eth.getTransactionReceipt config.txId)
    , Task.attempt (GetTransactionCount "getTransactionCount") (Web3.Eth.getTransactionCount config.blockNumber config.account)
    , Task.attempt (Sign "sign") (Web3.Eth.sign config.account config.hexData)
    , Task.attempt (SignTransaction "signTransaction") (Web3.Eth.signTransaction config.account config.txParams)
    , Task.attempt (Call "call") (Web3.Eth.call Nothing config.txParams)
    , Task.attempt (CallAtBlock "callAtBlock") (Web3.Eth.callAtBlock config.blockNumber Nothing config.txParams)
    , Task.attempt (EstimateGas "estimateGas") (Web3.Eth.estimateGas config.txParams)
    , Task.attempt (GetPastLogs "getPastLogs") (Web3.Eth.getPastLogs config.filterParams)
    , Task.attempt (GetId "getId") (Web3.Eth.getId)
    , Task.attempt (IsListening "isListening") (Web3.Eth.isListening)
    , Task.attempt (GetPeerCount "getPeerCount") (Web3.Eth.getPeerCount)
    , Task.attempt (GetNetworkType "getNetworkType") (Web3.Eth.getNetworkType)
    , Task.attempt (CurrentProviderUrl "currentProviderUrl") (Web3.Eth.currentProviderUrl)
    ]



-- manualCommands =
--     [ Task.attempt (SendTransaction "sendTransaction") (Web3.Eth.sendTransaction)
--     , Task.attempt (SendSignedTransaction "sendSignedTransaction") (Web3.Eth.sendSignedTransaction)
--     , Task.attempt (ManualCall "call") (Web3.Eth.call)
--     ]


viewTest : Test -> Element Styles Variations Msg
viewTest test =
    row TestRow
        [ spacing 20, paddingXY 20 20 ]
        [ column TestPassed [ vary Pass test.passed, vary Fail (not test.passed) ] [ text <| toString test.passed ]
        , column TestName [ paddingXY 20 0 ] [ text test.name ]
        , column TestResponse [ attribute "title" test.response, maxWidth <| percent 70 ] [ text test.response ]
        ]


view : Model -> Element Styles Variations Msg
view model =
    let
        testsTable =
            model.tests
                ?= Dict.empty
                |> Dict.values
                |> List.map viewTest

        titleRow =
            [ row TestTitle
                [ padding 30, center ]
                [ text "Web3.Eth" ]
            ]

        testButtons =
            [ row TestRow
                [ spacing 20, paddingXY 20 20 ]
                [ button Button [ onClick InitTests, paddingXY 20 0 ] (text "Start Tests")
                , button Button [ onClick InitSendTransaction, paddingXY 20 0 ] (text "Send Tx")
                , button Button [ onClick InitSendSignedTransaction, paddingXY 20 0 ] (text "Send Signed Tx")
                ]
            ]
    in
        column None
            [ width fill, scrollbars ]
            (titleRow ++ testButtons ++ testsTable)


type Msg
    = InitTests
    | InitSendTransaction
    | SendTransaction String (Result Error TxId)
    | InitSendSignedTransaction
    | SendSignedTransaction String (Result Error TxId)
    | GetProtocolVersion String (Result Error String)
    | IsSyncing String (Result Error (Maybe SyncStatus))
    | GetCoinbase String (Result Error Address)
    | IsMining String (Result Error Bool)
    | GetHashrate String (Result Error Int)
    | GetGasPrice String (Result Error BigInt)
    | GetAccounts String (Result Error (List Address))
    | GetBlockNumber String (Result Error BlockId)
    | GetBalance String (Result Error BigInt)
    | GetStorageAt String (Result Error Hex)
    | GetStorageAtBlock String (Result Error Hex)
    | GetCode String (Result Error Hex)
    | GetCodeAtBlock String (Result Error Hex)
    | GetBlockTransactionCount String (Result Error (Maybe Int))
    | GetBlock String (Result Error (Maybe (Block TxId)))
    | GetBlockTxObjs String (Result Error (Maybe (Block TxObj)))
    | GetBlockUncleCount String (Result Error (Maybe Int))
    | GetUncle String (Result Error (Maybe (Block TxId)))
    | GetUncleTxObjs String (Result Error (Maybe (Block TxObj)))
    | GetTransaction String (Result Error (Maybe TxObj))
    | GetTransactionFromBlock String (Result Error (Maybe TxObj))
    | GetTransactionReceipt String (Result Error (Maybe TxReceipt))
    | GetTransactionCount String (Result Error (Maybe Int))
    | Sign String (Result Error Hex)
    | SignTransaction String (Result Error SignedTx)
    | Call String (Result Error Hex)
    | CallAtBlock String (Result Error Hex)
    | EstimateGas String (Result Error Int)
    | GetPastLogs String (Result Error (List Log))
    | GetId String (Result Error Int)
    | IsListening String (Result Error Bool)
    | GetPeerCount String (Result Error Int)
    | GetNetworkType String (Result Error Network)
    | CurrentProviderUrl String (Result Error String)


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    let
        updateTest key val =
            (model.tests ?= Dict.empty) |> (Dict.insert key val >> Just)

        updateModel key funcName result =
            case result of
                Ok val ->
                    { model | tests = updateTest key (Test funcName (Debug.log "ELM UPDATE OK: " <| toString val) True) }

                Err (Error err) ->
                    { model | tests = updateTest key { name = funcName, response = (Debug.log "ELM UPDATE ERR: " <| toString err), passed = False } }
    in
        case msg of
            InitTests ->
                model ! testCommands config

            InitSendTransaction ->
                model ! [ Task.attempt (SendTransaction "sendTransaction") (Web3.Eth.sendTransaction config.account config.txParams) ]

            SendTransaction funcName result ->
                updateModel 1 funcName result ! []

            InitSendSignedTransaction ->
                model ! [ Task.attempt (SendSignedTransaction "sendSignedTransaction") (Web3.Eth.sendTransaction config.account config.txParams) ]

            SendSignedTransaction funcName result ->
                updateModel 2 funcName result ! []

            GetProtocolVersion funcName result ->
                updateModel 10 funcName result ! []

            IsSyncing funcName result ->
                updateModel 20 funcName result ! []

            GetCoinbase funcName result ->
                updateModel 30 funcName result ! []

            IsMining funcName result ->
                updateModel 40 funcName result ! []

            GetHashrate funcName result ->
                updateModel 50 funcName result ! []

            GetGasPrice funcName result ->
                updateModel 60 funcName result ! []

            GetAccounts funcName result ->
                updateModel 70 funcName result ! []

            GetBlockNumber funcName result ->
                updateModel 80 funcName result ! []

            GetBalance funcName result ->
                updateModel 90 funcName result ! []

            GetStorageAt funcName result ->
                updateModel 100 funcName result ! []

            GetStorageAtBlock funcName result ->
                updateModel 110 funcName result ! []

            GetCode funcName result ->
                updateModel 120 funcName result ! []

            GetCodeAtBlock funcName result ->
                updateModel 130 funcName result ! []

            GetBlockTransactionCount funcName result ->
                updateModel 140 funcName result ! []

            GetBlock funcName result ->
                updateModel 150 funcName result ! []

            GetBlockTxObjs funcName result ->
                updateModel 160 funcName result ! []

            GetBlockUncleCount funcName result ->
                updateModel 170 funcName result ! []

            GetUncle funcName result ->
                updateModel 180 funcName result ! []

            GetUncleTxObjs funcName result ->
                updateModel 190 funcName result ! []

            GetTransaction funcName result ->
                updateModel 200 funcName result ! []

            GetTransactionFromBlock funcName result ->
                updateModel 210 funcName result ! []

            GetTransactionReceipt funcName result ->
                updateModel 220 funcName result ! []

            GetTransactionCount funcName result ->
                updateModel 230 funcName result ! []

            Sign funcName result ->
                updateModel 260 funcName result ! []

            SignTransaction funcName result ->
                updateModel 270 funcName result ! []

            Call funcName result ->
                updateModel 280 funcName result ! []

            CallAtBlock funcName result ->
                updateModel 290 funcName result ! []

            EstimateGas funcName result ->
                updateModel 300 funcName result ! []

            GetPastLogs funcName result ->
                updateModel 310 funcName (Err (Error "Function doesn't seem to work yet")) ! []

            GetId funcName result ->
                updateModel 320 funcName result ! []

            IsListening funcName result ->
                updateModel 330 funcName result ! []

            GetPeerCount funcName result ->
                updateModel 340 funcName result ! []

            GetNetworkType funcName result ->
                updateModel 350 funcName result ! []

            CurrentProviderUrl funcName result ->
                updateModel 360 funcName result ! []
