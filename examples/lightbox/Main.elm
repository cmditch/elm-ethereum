module Main exposing (..)

import Task
import Html exposing (..)
import Html.Attributes exposing (href, target)
import Html.Events exposing (onClick, onInput)
import Web3 exposing (Error(..), toTask)
import Web3.Eth.Decoders exposing (txIdToString, addressToString)
import Web3.Eth.Types exposing (..)
import Web3.Eth.Contract as Contract
import LightBox as LB
import BigInt exposing (BigInt)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { latestBlock : Maybe Block
    , contractInfo : DeployableContract
    , coinbase : Address
    , additionAnswer : Maybe BigInt
    , txIds : List TxId
    , error : List String
    , testData : String
    , eventData : List String
    , uintLogs : List (EventLog LB.UintArrayArgs)
    , isWatchingAdd : Bool
    }


init : ( Model, Cmd Msg )
init =
    { latestBlock = Nothing
    , contractInfo =
        Deployed <|
            ContractInfo (Address "0xeb8f5983d099b0be3f78367bf5efccb5df9e3487")
                (TxId "0x742f7f7e2f564159dece37e1fc0d6454bef638bdf57ecea576baf94718863de3")
    , coinbase = Address "0xe87529a6123a74320e13a6dabf3606630683c029"
    , additionAnswer =
        "123412341234123412342143125312351235123512"
            |> BigInt.fromString
            >> Maybe.withDefault (BigInt.fromInt -1)
            |> Just
    , txIds = []
    , error = []
    , testData = ""
    , eventData = []
    , uintLogs = []
    , isWatchingAdd = False
    }
        ! [{- TODO Web3.init command needed. Program w/ flags  for wallet check and web3 connection status -}]


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
                , div [] [ button [ onClick (MutateAdd address 42) ] [ text <| "Add 42 to someNum" ] ]
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


viewBlock : Maybe Block -> Html Msg
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
    = Test
    | TestResponse (Result Web3.Error ())
    | WatchAdd
    | StopWatchingAdd
    | Reset
    | AddEvents String
    | UintArrayEvents (Result String (EventLog LB.UintArrayArgs))
    | DeployContract
    | AddNumbers Address Int Int
    | MutateAdd Address Int
    | LatestResponse (Result Web3.Error Block)
    | LightBoxResponse (Result Web3.Error ContractInfo)
    | LightBoxAddResponse (Result Web3.Error BigInt)
    | LightBoxMutateAddResponse (Result Web3.Error TxId)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        handleError model_ error =
            case error of
                Web3.Error e ->
                    { model_ | error = e :: model_.error } ! []

                Web3.BadPayload e ->
                    { model_ | error = ("decoding error: " ++ e) :: model_.error } ! []

                Web3.NoWallet ->
                    { model_ | error = ("No Wallet Detected") :: model_.error } ! []
    in
        case msg of
            Test ->
                model ! [ Task.attempt TestResponse (Web3.reset False) ]

            TestResponse response ->
                case response of
                    Ok data ->
                        { model | testData = "It'werked" } ! []

                    Err error ->
                        handleError model error

            WatchAdd ->
                case model.contractInfo of
                    Deployed { address } ->
                        { model | isWatchingAdd = True }
                            ! [ LB.watchAdd_ address LB.addFilter "addLog"
                              , LB.watchUintArray_ address LB.uintArrayFilter "uintArrayLog"
                              ]

                    _ ->
                        model ! []

            StopWatchingAdd ->
                { model | isWatchingAdd = False } ! [ Contract.stopWatching "bobAdds" ]

            AddEvents events ->
                { model | eventData = events :: model.eventData } ! []

            UintArrayEvents result ->
                case result of
                    Ok log ->
                        let
                            newLogs =
                                log :: model.uintLogs
                        in
                            { model | uintLogs = newLogs, eventData = toString newLogs :: model.eventData } ! []

                    Err err ->
                        { model | error = err :: model.error } ! []

            Reset ->
                { model | isWatchingAdd = False } ! [ Contract.reset ]

            DeployContract ->
                { model | contractInfo = Deploying }
                    ! [ Task.attempt LightBoxResponse <|
                            LB.new
                                (BigInt.fromString "502030200")
                                { someNum_ = BigInt.fromInt 13 }
                      ]

            AddNumbers address a b ->
                model
                    ! [ Task.attempt LightBoxAddResponse
                            (LB.add address a b)
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
        , Contract.sentry "uintArrayLog" (LB.decodeUintArrayArgs >> UintArrayEvents)
        ]
