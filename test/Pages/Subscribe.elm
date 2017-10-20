module Pages.Subscribe exposing (..)

import Element exposing (..)
import Config exposing (..)
import Dict exposing (Dict)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Web3.Types exposing (..)
import Web3.Eth.Subscribe as Subscribe


init : Model
init =
    { tests = Nothing
    , latestBlockHeaders = []
    , latestTxs = []
    , syncing = []
    , logs = []
    , listeningBlockHeaders = False
    , listeningTxs = False
    , listeningSyncing = False
    , listeningLogs = False
    , error = Nothing
    }


type alias Model =
    { tests : Maybe (Dict Int Test)
    , latestBlockHeaders : List String
    , latestTxs : List String
    , syncing : List String
    , logs : List String
    , listeningBlockHeaders : Bool
    , listeningTxs : Bool
    , listeningSyncing : Bool
    , listeningLogs : Bool
    , error : Maybe Error
    }


testCommands : Config -> List (Cmd Msg)
testCommands config =
    []


viewTest : Test -> Element Styles Variations Msg
viewTest test =
    row TestRow
        [ spacing 20, paddingXY 20 20 ]
        [ column TestPassed [ vary Pass test.passed, vary Fail (not test.passed), verticalCenter ] [ text <| toString test.passed ]
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
                [ text "Web3.Eth.Subscribe" ]
            ]

        viewSubButton isListening startMsg stopMsg buttonText =
            case isListening of
                False ->
                    button Button [ onClick startMsg, paddingXY 20 0 ] (text <| "Start " ++ buttonText)

                True ->
                    button Button [ onClick stopMsg, paddingXY 20 0 ] (text <| "Stop " ++ buttonText)

        testButtons =
            [ row TestRow
                [ spacing 20, paddingXY 20 20 ]
                [ viewSubButton model.listeningBlockHeaders StartLatestBlocks StopLatestBlocks "Latest Block Headers"
                , viewSubButton model.listeningTxs StartLatestTxs StopLatestTxs "Latest Txs"
                , viewSubButton model.listeningSyncing StartSyncing StopSyncing "Syncing"
                , viewSubButton model.listeningLogs StartLogs StopLogs "Logs"

                -- , button Button [ onClick ClearSubscriptions, paddingXY 20 0 ] (text "Clear Subscriptions")
                ]
            ]

        viewSub ( name, logList ) =
            viewTest
                (Test
                    (name ++ ": " ++ toString (List.length logList))
                    (toString logList)
                    True
                )

        subs =
            List.map viewSub
                [ ( "Block Headers", model.latestBlockHeaders )
                , ( "Transactions", model.latestTxs )
                , ( "Syncing", model.syncing )
                , ( "Logs", model.logs )
                ]
    in
        column None
            [ width fill, scrollbars ]
            (titleRow ++ testButtons ++ subs ++ testsTable)


type Msg
    = StartLatestBlocks
    | StartLatestTxs
    | StartSyncing
    | StartLogs
    | StopLatestBlocks
    | StopLatestTxs
    | StopSyncing
    | StopLogs
    | GetLatestBlocks (Result Error BlockHeader)
    | GetLatestTxs (Result Error TxId)
    | GetSyncing (Result Error (Maybe SyncStatus))
    | GetLogs (Result Error String)
    | ClearSubscriptions


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    let
        updateTest key val =
            Just <| Dict.insert key val (model.tests ?= Dict.empty)

        updateModel key funcName result =
            case result of
                Ok val ->
                    { model | tests = updateTest key (Test funcName (toString val) True) }

                Err (Error err) ->
                    { model | tests = updateTest key { name = funcName, response = (toString err), passed = False } }

        handleResult result =
            case result of
                Ok a ->
                    toString a

                Err (Error err) ->
                    err
    in
        case msg of
            StartLatestBlocks ->
                { model | listeningBlockHeaders = True } ! [ Subscribe.start NewBlockHeaders ]

            StartLatestTxs ->
                { model | listeningTxs = True } ! [ Subscribe.start PendingTxs ]

            StartSyncing ->
                { model | listeningSyncing = True } ! [ Subscribe.start Syncing ]

            StartLogs ->
                { model | listeningLogs = True } ! []

            StopLatestBlocks ->
                { model | listeningBlockHeaders = False } ! [ Subscribe.stop NewBlockHeaders ]

            StopLatestTxs ->
                { model | listeningTxs = False } ! [ Subscribe.stop PendingTxs ]

            StopSyncing ->
                { model | listeningSyncing = False } ! [ Subscribe.stop Syncing ]

            StopLogs ->
                { model | listeningLogs = False } ! []

            GetLatestBlocks result ->
                { model | latestBlockHeaders = handleResult result :: model.latestBlockHeaders } ! []

            GetLatestTxs result ->
                { model | latestTxs = handleResult result :: model.latestTxs } ! []

            GetSyncing result ->
                { model | syncing = handleResult result :: model.syncing } ! []

            GetLogs result ->
                { model | logs = handleResult result :: model.logs } ! []

            ClearSubscriptions ->
                { model | listeningBlockHeaders = False, listeningTxs = False, listeningSyncing = False }
                    ! [ Subscribe.clearSubscriptions True ]
