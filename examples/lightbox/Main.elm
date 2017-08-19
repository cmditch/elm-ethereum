module Main exposing (..)

import Task
import Html exposing (..)
import Html.Attributes exposing (href, target)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Process
import BigInt exposing (BigInt)
import Web3 exposing (toTask)
import Web3.Eth exposing (defaultFilterParams)
import Web3.Decoders exposing (txIdToString, addressToString)
import Web3.Types exposing (..)
import Web3.Eth.Contract as Contract
import LightBox as LB exposing (addFilter_)


(:>) task =
    Task.andThen (\_ -> task)


(&>) =
    Task.andThen


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { latestBlock : Maybe (Block String)
    , contractInfo : DeployableContract
    , coinbase : Maybe Address
    , additionAnswer : Maybe BigInt
    , txIds : List TxId
    , error : List String
    , testData : String
    , eventData : List String
    , uintLogs : List (EventLog LB.UintArrayArgs)
    , addLogs : List (EventLog LB.AddArgs)
    , isWatchingAdd : Bool
    }


init : ( Model, Cmd Msg )
init =
    { latestBlock = Nothing
    , contractInfo =
        Deployed <|
            ContractInfo (Address "0xa10b5565C1f5d9Ca24c990104Ea28171727ab3A6")
                (TxId "0xe00974189a05a33921ce0e578fcff486fd3a754b017ae7a8bc82cfdf4fb51dea")
    , coinbase = Nothing
    , additionAnswer = Nothing
    , txIds = []
    , error = []
    , testData = ""
    , eventData = []
    , uintLogs = []
    , addLogs = []
    , isWatchingAdd = False
    }
        ! [ Web3.Eth.setDefaultAccount (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
                |> Web3.retry { attempts = 10, sleep = 1 }
                |> Task.attempt SetCoinbase
          ]


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick DeployContract ] [ text "Deploy new LightBox" ]
        , viewContractInfo model.contractInfo
        , bigBreak
        , viewAddButton model
        , bigBreak
        , div [] [ text <| "Tx History: " ++ toString model.txIds ]
        , bigBreak
        , viewEventStuff model
        , bigBreak
        , viewError model.error
        , button [ onClick Test ] [ text "Try web3.reset()" ]
        , div [] [ text model.testData ]
        ]


bigBreak : Html Msg
bigBreak =
    div []
        [ br [] []
        , br [] []
        , br [] []
        ]


viewEventStuff : Model -> Html Msg
viewEventStuff model =
    div []
        [ div [] [ text "Logs from AddEvents" ]
        , div [] (List.map viewMessage model.eventData)
        , bigBreak
        , viewButton model
        , br [] []
        , button [ onClick Reset ] [ text "Reset all events" ]
        ]


viewMessage : String -> Html Msg
viewMessage msg =
    div []
        [ text msg ]


viewButton : Model -> Html Msg
viewButton model =
    case model.isWatchingAdd of
        False ->
            button [ onClick WatchAdd ] [ text "Watch For Event" ]

        True ->
            button [ onClick StopWatchingAdd ] [ text "Stop Watching the Event" ]


viewAddButton : Model -> Html Msg
viewAddButton model =
    case model.contractInfo of
        Deployed { address } ->
            div []
                [ text "You can call LightBox.add(11,12)"
                , div [] [ button [ onClick (AddNumbers address 11 12) ] [ text <| viewMaybeBigInt model.additionAnswer ] ]
                , bigBreak
                , div [] [ button [ onClick (MutateAdd address 42) ] [ text "Add 42 to someNum" ] ]
                , bigBreak
                , div [] [ button [ onClick GetAdd ] [ text "Get some logs" ] ]
                ]

        _ ->
            div [] []


viewContractInfo : DeployableContract -> Html Msg
viewContractInfo contract =
    case contract of
        UnDeployed ->
            div [] [ text "No contract deployed" ]

        Deploying ->
            div [] [ text "Deploying contract..." ]

        Deployed { address, txId } ->
            div []
                [ p []
                    [ text "Contract TxId: "
                    , a [ target "_blank", href ("https://ropsten.etherscan.io/tx/" ++ txIdToString txId) ]
                        [ text <| txIdToString txId ]
                    ]
                , br [] []
                , p []
                    [ text "Contract Address: "
                    , a [ target "_blank", href ("https://ropsten.etherscan.io/address/" ++ addressToString address) ]
                        [ text <| addressToString address ]
                    ]
                ]

        ErrorDeploying ->
            div [] [ text "Error deploying contract." ]


type DeployableContract
    = UnDeployed
    | Deploying
    | Deployed ContractInfo
    | ErrorDeploying


viewMaybeBigInt : Maybe BigInt -> String
viewMaybeBigInt mBigInt =
    case mBigInt of
        Nothing ->
            "Add"

        Just bigInt ->
            BigInt.toString bigInt


viewBlock : Maybe (Block String) -> Html Msg
viewBlock block =
    case block of
        Nothing ->
            div [] [ text "Awaiting Block info..." ]

        Just block_ ->
            div [] [ text <| toString block_ ]


viewAddress : Maybe Address -> Html Msg
viewAddress address =
    case address of
        Nothing ->
            div [] [ text "Awaiting Address info..." ]

        Just address_ ->
            div [] [ text <| addressToString address_ ]


viewError : List String -> Html Msg
viewError error =
    case error of
        [] ->
            div [] [ text "Errors: " ]

        _ ->
            div [] [ text <| "Errors: " ++ toString error ]


type Msg
    = SetCoinbase (Result Error Address)
    | Test
    | TestResponse (Result Error ())
    | GetAdd
    | RecieveGetAdd (Result Error (List (EventLog LB.AddArgs)))
    | WatchAdd
    | StopWatchingAdd
    | Reset
    | AddEvents String
    | UintArrayEvents (Result String (EventLog LB.UintArrayArgs))
    | DeployContract
    | AddNumbers Address Int Int
    | MutateAdd Address Int
    | LatestResponse (Result Error (Block String))
    | LightBoxResponse (Result Error ContractInfo)
    | LightBoxAddResponse (Result Error BigInt)
    | LightBoxMutateAddResponse (Result Error TxId)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        handleError model_ error =
            case error of
                Error e ->
                    { model_ | error = e :: model_.error } ! []

                BadPayload e ->
                    { model_ | error = ("decoding error: " ++ e) :: model_.error } ! []

                NoWallet ->
                    { model_ | error = ("No Wallet Detected") :: model_.error } ! []
    in
        case msg of
            SetCoinbase resultAddress ->
                let
                    resultAddress_ =
                        if resultAddress |> Result.andThen Web3.isAddress |> Result.withDefault False then
                            resultAddress
                                |> Result.andThen Web3.toChecksumAddress
                        else
                            Err (Error "Not a valid address.")
                in
                    case resultAddress_ of
                        Err err ->
                            handleError model err

                        Ok address_ ->
                            { model | coinbase = Just address_ } ! []

            Test ->
                model ! [ Task.attempt TestResponse (Web3.reset False) ]

            TestResponse response ->
                case response of
                    Ok data ->
                        { model | testData = "It'werked" } ! []

                    Err error ->
                        handleError model error

            GetAdd ->
                case model.contractInfo of
                    Deployed { address } ->
                        model
                            ! [ Task.attempt RecieveGetAdd <|
                                    LB.get_ LB.decodeAddLog_
                                        (LB.Add addFilter_
                                            { defaultFilterParams | fromBlock = Just (BlockNum 1), toBlock = Just Latest }
                                        )
                                        address
                              ]

                    _ ->
                        model ! []

            RecieveGetAdd result ->
                case result of
                    Err err ->
                        handleError model err

                    Ok logs ->
                        { model | addLogs = logs ++ model.addLogs } ! []

            WatchAdd ->
                case model.contractInfo of
                    Deployed { address } ->
                        { model | isWatchingAdd = True }
                            ! [ LB.watch_ (LB.Add { addFilter_ | sum = Just [ 55 ] } defaultFilterParams) address "addLog"
                              , LB.watch_ (LB.UintArray LB.uintArrayFilter_ defaultFilterParams) address "uintArrayLog"
                              ]

                    _ ->
                        model ! []

            StopWatchingAdd ->
                { model | isWatchingAdd = False }
                    ! [ LB.stopWatching_ "addLog"
                      , LB.stopWatching_ "uintArrayLog"
                      ]

            AddEvents events ->
                { model | eventData = events :: model.eventData } ! []

            UintArrayEvents result ->
                case result of
                    Ok log ->
                        let
                            newLogs =
                                log :: model.uintLogs

                            stringedBigInts =
                                List.map BigInt.toString log.args.uintArray
                        in
                            { model | uintLogs = newLogs, eventData = toString stringedBigInts :: model.eventData } ! []

                    Err err ->
                        { model | error = err :: model.error } ! []

            Reset ->
                { model | isWatchingAdd = False } ! [ Contract.reset ]

            DeployContract ->
                { model | contractInfo = Deploying }
                    ! [ Task.attempt LightBoxResponse <|
                            LB.new_
                                (BigInt.fromString "502030200")
                                { someNum_ = BigInt.fromInt 13 }
                      ]

            AddNumbers address a b ->
                model
                    ! [ Task.attempt LightBoxAddResponse
                            (LB.add_ address a b)
                      ]

            LatestResponse response ->
                case response of
                    Ok block ->
                        { model | latestBlock = Just block } ! []

                    Err error ->
                        handleError { model | latestBlock = Nothing } error

            LightBoxResponse response ->
                case response of
                    Ok contractInfo ->
                        { model | contractInfo = Deployed contractInfo } ! []

                    Err error ->
                        handleError { model | contractInfo = ErrorDeploying } error

            LightBoxAddResponse response ->
                case response of
                    Ok theSum ->
                        { model | additionAnswer = Just theSum } ! []

                    Err error ->
                        handleError model error

            MutateAdd address a ->
                model
                    ! [ Task.attempt LightBoxMutateAddResponse
                            (LB.mutateAdd address a)
                      ]

            LightBoxMutateAddResponse response ->
                case response of
                    Ok txId ->
                        { model | txIds = txId :: model.txIds } ! []

                    Err error ->
                        handleError model error


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Contract.sentry "addLog" AddEvents
        , Contract.sentry "uintArrayLog" (Decode.decodeString LB.decodeUintArrayLog_ >> UintArrayEvents)
        ]
