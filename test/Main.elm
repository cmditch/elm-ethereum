module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Dict
import Task
import BigInt exposing (BigInt)
import Web3
import Web3.Types exposing (..)
import Web3.Version
import Web3.Net
import Web3.Eth


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    { tests = Dict.empty
    , network = Nothing
    , error = Nothing
    }
        ! [ Task.attempt EstablishNetworkId
                (Web3.retry { sleep = 1, attempts = 30 } Web3.Version.getNetwork)
          ]


type alias Model =
    { tests : Dict.Dict Int Test
    , network : Maybe EthNetwork
    , error : Maybe Error
    }


type alias Test =
    { name : String
    , result : String
    , passed : Bool
    }


type alias Config =
    { account : Address
    , contract : Address
    , blockNumber : BlockId
    , blockHash : BlockId
    , txId : TxId
    }


type EthNetwork
    = MainNet
    | Ropsten
    | UnknownNetwork


mainnetConfig : Config
mainnetConfig =
    { account = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , contract = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , blockNumber = BlockNum 4182808
    , blockHash = BlockHash "0x000997b870b069a5b1857de507103521860590ca747cf16e46ee38ac456d204e"
    , txId = TxId "0x0bb84e278f50d334022a2c239c90f3c186867b0888e989189ac3c19b27c70372"
    }


ropstenConfig : Config
ropstenConfig =
    { account = (Address "0x10A19C4bD26C8E8203628384083b7ee6819e36B6")
    , contract = (Address "0xdfbE7B4439682E2Ad6F33323b36D89aBF8f295F9")
    , blockNumber = BlockNum 1530779
    , blockHash = BlockHash "0x1562e2c2506d2cfad8a95ef78fd48b507c3ffa62c44a3fc619facc4af191b3de"
    , txId = TxId "0x444b76b68af09969f46eabbbe60eef38f4b0674c4a7cb2e32c7764096997b916"
    }


testCommands : EthNetwork -> List (Cmd Msg)
testCommands network =
    let
        config =
            case network of
                MainNet ->
                    mainnetConfig

                Ropsten ->
                    ropstenConfig

                UnknownNetwork ->
                    ropstenConfig
    in
        taskChains config
            ++ [ -- web3.version
                 Task.attempt (VersionApi "web3.version.api") Web3.Version.api
               , Task.attempt (VersionGetNode "web3.version.getNode") Web3.Version.getNode
               , Task.attempt (VersionGetNetwork "web3.version.getNetwork") Web3.Version.getNetwork
               , Task.attempt (VersionGetEthereum "web3.version.getEthereum") Web3.Version.getEthereum

               -- web3
               , Task.attempt (IsConnected "web3.isConnected") Web3.isConnected
               , Task.attempt (Sha3 "web3.sha3") (Web3.sha3 "History is not a burden on the memory but an illumination of the soul.")
               , Task.attempt (ToHex "web3.toHex") (Web3.toHex "The danger is not that a particular class is unfit to govern. Every class is unfit to govern.")
               , Task.attempt (ToAscii "web3.toAscii") (Web3.toAscii (Hex "0x4f6e20736f6d6520677265617420616e6420676c6f72696f7573206461792074686520706c61696e20666f6c6b73206f6620746865206c616e642077696c6c207265616368207468656972206865617274277320646573697265206174206c6173742c20616e642074686520576869746520486f7573652077696c6c2062652061646f726e6564206279206120646f776e7269676874206d6f726f6e2e202d20482e4c2e204d656e636b656e"))
               , Task.attempt (FromAscii "web3.fromAscii") (Web3.fromAscii "'I'm not a driven businessman, but a driven artist. I never think about money. Beautiful things make money.'")
               , Task.attempt (ToDecimal "web3.toDecimal") (Web3.toDecimal (Hex "0x67932"))
               , Task.attempt (FromDecimal "web3.fromDecimal") (Web3.fromDecimal 424242)
               , Task.attempt (IsAddress "web3.isAddress") (Web3.isAddress config.account)
               , Task.attempt (IsChecksumAddress "web3.isChecksumAddress") (Web3.isChecksumAddress config.account)
               , Task.attempt (ToChecksumAddress "web3.toChecksumAddress") (Web3.toChecksumAddress config.account)

               -- web3.net
               , Task.attempt (NetGetListening "web3.net.getListening") (Web3.Net.getListening)
               , Task.attempt (NetPeerCount "web3.net.getPeerCount") (Web3.Net.getPeerCount)

               -- web3.eth
               , Task.attempt (EthGetSyncing "web3.eth.getSyncing") (Web3.Eth.getSyncing)
               , Task.attempt (EthCoinbase "web3.eth.coinbase") (Web3.Eth.coinbase)
               , Task.attempt (EthGetHashrate "web3.eth.getHashrate") (Web3.Eth.getHashrate)
               , Task.attempt (EthGetGasPrice "web3.eth.getGasPrice") (Web3.Eth.getGasPrice)
               , Task.attempt (EthGetAccounts "web3.eth.getAccounts") (Web3.Eth.getAccounts)
               , Task.attempt (EthGetMining "web3.eth.getMining") (Web3.Eth.getMining)
               , Task.attempt (EthGetBlockNumber "web3.eth.getBlockNumber") (Web3.Eth.getBlockNumber)
               , Task.attempt (EthGetBalance "web3.eth.getBalance") (Web3.Eth.getBalance config.account)
               , Task.attempt (EthGetStorageAt "web3.eth.getStorageAt") (Web3.Eth.getStorageAt config.contract 1)
               , Task.attempt (EthGetCode "web3.eth.getCode") (Web3.Eth.getCode config.contract)
               , Task.attempt (EthGetBlock "web3.eth.getBlock") (Web3.Eth.getBlock config.blockNumber)
               , Task.attempt (EthGetBlockTxObjs "web3.eth.getBlockTxObjs") (Web3.Eth.getBlockTxObjs config.blockNumber)
               , Task.attempt (EthGetBlockTransactionCount "web3.eth.getBlockTransactionCount") (Web3.Eth.getBlockTransactionCount config.blockNumber)
               , Task.attempt (EthGetUncle "web3.eth.getUncle") (Web3.Eth.getUncle config.blockNumber 0)
               , Task.attempt (EthGetBlockUncleCount "web3.eth.getBlockUncleCount") (Web3.Eth.getBlockUncleCount config.blockNumber)
               , Task.attempt (EthGetTransaction "web3.eth.getTransaction") (Web3.Eth.getTransaction config.txId)
               ]


taskChains : Config -> List (Cmd Msg)
taskChains config =
    [ Task.attempt (TaskChainStorageToAscii "getStorageAt -> toAscii")
        (Web3.Eth.getStorageAt config.contract 1 |> Task.andThen Web3.toAscii)
    ]


view : Model -> Html Msg
view model =
    let
        tableHead =
            thead []
                [ tr []
                    [ th [] [ text "Function" ]
                    , th [] [ text "Details" ]
                    , th [] [ text "Result" ]
                    , th [] [ button [ onClick StartTest ] [ text "Run Tests" ] ]
                    ]
                ]

        tableBody =
            model.tests
                |> Dict.toList
                |> List.map viewTestRow
                |> tbody []
    in
        div []
            [ viewCoverage model
            , table [] [ tableHead, tableBody ]
            ]


viewTestRow : ( Int, Test ) -> Html Msg
viewTestRow ( _, test ) =
    let
        concatText string =
            if String.length string > 50 then
                text <| (String.left 50 string) ++ "...\""
            else
                text string
    in
        tr []
            [ td [] [ text test.name ]
            , td [ class "result", title test.result ] [ concatText test.result ]
            , viewTestResult test
            ]


viewTestResult : Test -> Html Msg
viewTestResult test =
    case test.passed of
        True ->
            td [ greenText ] [ text "Pass" ]

        False ->
            td [ redText ] [ text "Fail" ]


viewCoverage : Model -> Html Msg
viewCoverage model =
    let
        quantityTests =
            List.length (testCommands (model.network ?= UnknownNetwork))

        quantityTestsRun =
            (Dict.keys model.tests |> List.length)

        allTestsExecuted =
            quantityTests == quantityTestsRun

        styling =
            if allTestsExecuted then
                greenText
            else
                redText
    in
        div [ styling ]
            [ text <|
                toString quantityTestsRun
                    ++ " out of "
                    ++ toString quantityTests
                    ++ " tests returned a value"
            ]


type Msg
    = EstablishNetworkId (Result Error String)
    | StartTest
    | VersionApi String (Result Error String)
    | VersionGetNode String (Result Error String)
    | VersionGetNetwork String (Result Error String)
    | VersionGetEthereum String (Result Error String)
    | IsConnected String (Result Error Bool)
      -- web3.setProvider
      -- web3.currentProvider
      -- web3.reset
    | Sha3 String (Result Error Keccak256)
    | ToHex String (Result Error Hex)
    | ToAscii String (Result Error String)
    | FromAscii String (Result Error Hex)
    | ToDecimal String (Result Error Int)
    | FromDecimal String (Result Error Hex)
      -- fromWei
      -- toWei
    | IsAddress String (Result Error Bool)
    | IsChecksumAddress String (Result Error Bool)
    | ToChecksumAddress String (Result Error Address)
    | NetGetListening String (Result Error Bool)
    | NetPeerCount String (Result Error Int)
      -- web3.ethdefaultAccount
    | EthGetSyncing String (Result Error (Maybe SyncStatus))
      -- web3.eth.isSyncing
    | EthCoinbase String (Result Error Address)
    | EthGetHashrate String (Result Error Int)
    | EthGetGasPrice String (Result Error BigInt)
    | EthGetAccounts String (Result Error (List Address))
    | EthGetMining String (Result Error Bool)
    | EthGetBlockNumber String (Result Error BlockId)
    | EthGetBalance String (Result Error BigInt)
    | EthGetStorageAt String (Result Error Hex)
    | EthGetCode String (Result Error Bytes)
    | EthGetBlock String (Result Error BlockTxIds)
    | EthGetBlockTxObjs String (Result Error BlockTxObjs)
    | EthGetBlockTransactionCount String (Result Error Int)
    | EthGetUncle String (Result Error (Maybe BlockTxIds))
    | EthGetBlockUncleCount String (Result Error Int)
    | EthGetTransaction String (Result Error TxObj)
      -- Fun funcs
    | TaskChainStorageToAscii String (Result Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        updateModel key funcName result =
            case result of
                Ok val ->
                    { model | tests = Dict.insert key (Test funcName (Debug.log "ELM UPDATE OK: " <| toString val) True) model.tests }

                Err error ->
                    case error of
                        Error err ->
                            { model | tests = Dict.insert key (Test funcName (Debug.log "ELM UPDATE ERR: " <| toString err) False) model.tests }

                        BadPayload err ->
                            { model | tests = Dict.insert key (Test funcName (Debug.log "ELM UPDATE ERR: " <| toString err) False) model.tests }

                        NoWallet ->
                            { model | tests = Dict.insert key (Test funcName "ELM UPDATE ERR" False) model.tests }
    in
        case msg of
            EstablishNetworkId result ->
                case result of
                    Ok networkId ->
                        update StartTest { model | network = Just (getNetwork networkId) }

                    Err err ->
                        { model | error = Just err } ! []

            StartTest ->
                case model.network of
                    Just network ->
                        model ! testCommands network

                    Nothing ->
                        model ! []

            VersionApi funcName result ->
                updateModel 1 funcName result ! []

            VersionGetNode funcName result ->
                updateModel 2 funcName result ! []

            VersionGetNetwork funcName result ->
                updateModel 3 funcName result ! []

            VersionGetEthereum funcName result ->
                updateModel 4 funcName result ! []

            IsConnected funcName result ->
                updateModel 5 funcName result ! []

            Sha3 funcName result ->
                updateModel 6 funcName result ! []

            ToHex funcName result ->
                updateModel 7 funcName result ! []

            ToAscii funcName result ->
                updateModel 8 funcName result ! []

            FromAscii funcName result ->
                updateModel 9 funcName result ! []

            ToDecimal funcName result ->
                updateModel 10 funcName result ! []

            FromDecimal funcName result ->
                updateModel 11 funcName result ! []

            IsAddress funcName result ->
                updateModel 12 funcName result ! []

            IsChecksumAddress funcName result ->
                updateModel 13 funcName result ! []

            ToChecksumAddress funcName result ->
                updateModel 14 funcName result ! []

            NetGetListening funcName result ->
                updateModel 15 funcName result ! []

            NetPeerCount funcName result ->
                updateModel 16 funcName result ! []

            EthGetSyncing funcName result ->
                updateModel 17 funcName result ! []

            EthCoinbase funcName result ->
                updateModel 18 funcName result ! []

            EthGetHashrate funcName result ->
                updateModel 19 funcName result ! []

            EthGetGasPrice funcName result ->
                updateModel 20 funcName result ! []

            EthGetAccounts funcName result ->
                updateModel 21 funcName result ! []

            EthGetMining funcName result ->
                updateModel 22 funcName result ! []

            EthGetBlockNumber funcName result ->
                updateModel 23 funcName result ! []

            EthGetBalance funcName result ->
                updateModel 24 funcName result ! []

            EthGetStorageAt funcName result ->
                updateModel 25 funcName result ! []

            EthGetCode funcName result ->
                updateModel 26 funcName result ! []

            EthGetBlock funcName result ->
                updateModel 27 funcName result ! []

            EthGetBlockTxObjs funcName result ->
                updateModel 28 funcName result ! []

            EthGetBlockTransactionCount funcName result ->
                updateModel 29 funcName result ! []

            EthGetUncle funcName result ->
                updateModel 30 funcName result ! []

            EthGetBlockUncleCount funcName result ->
                updateModel 31 funcName result ! []

            EthGetTransaction funcName result ->
                updateModel 32 funcName result ! []

            TaskChainStorageToAscii funcName result ->
                updateModel 100 funcName result ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []



--  Helpers


getNetwork : String -> EthNetwork
getNetwork id =
    case id of
        "1" ->
            MainNet

        "2" ->
            Ropsten

        _ ->
            UnknownNetwork


greenText : Attribute Msg
greenText =
    style [ ( "color", "green" ) ]


redText : Attribute Msg
redText =
    style [ ( "color", "red" ) ]


(?=) : Maybe a -> a -> a
(?=) a b =
    Maybe.withDefault b a
