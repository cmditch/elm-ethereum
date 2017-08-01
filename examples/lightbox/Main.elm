module Main exposing (..)

import Task
import Html exposing (..)
import Html.Attributes exposing (href, target)
import Html.Events exposing (onClick, onInput)
import Web3 exposing (Error(..), toTask)
import Web3.Eth exposing (defaultFilterParams)
import Web3.Eth.Types exposing (..)
import LightBox
import BigInt exposing (BigInt)
import Port


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
    , eventData : List (EventLog LightBox.AddArgs)
    }


init : ( Model, Cmd Msg )
init =
    { latestBlock = Nothing
    , contractInfo = Deployed <| ContractInfo "0xeb8f5983d099b0be3f78367bf5efccb5df9e3487" "0x742f7f7e2f564159dece37e1fc0d6454bef638bdf57ecea576baf94718863de3"
    , coinbase = "0xe87529a6123a74320e13a6dabf3606630683c029"
    , additionAnswer =
        "123412341234123412342143125312351235123512"
            |> BigInt.fromString
            >> Maybe.withDefault (BigInt.fromInt -1)
            |> Just
    , txIds = []
    , error = []
    , testData = ""
    , eventData = []
    }
        ! [{- TODO Web3.init command needed. Program w/ flags  for wallet check and web3 connection status -}]


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick DeployContract ] [ text "Deploy new LightBox" ]
        , viewContractInfo model.contractInfo
        , bigBreak
        , viewAddButton model

        -- , bigBreak
        -- , viewBlock model.latestBlock
        , bigBreak
        , div [] [ text <| "Tx History: " ++ toString model.txIds ]
        , bigBreak
        , button [ onClick WatchAddEvents ] [ text " Watch Add Event" ]
        , div [] [ text <| toString model.eventData ]
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


viewAddButton : Model -> Html Msg
viewAddButton model =
    case model.contractInfo of
        Deployed { contractAddress } ->
            div []
                [ text "You can call LightBox.add(11,12)"
                , div [] [ button [ onClick (AddNumbers contractAddress 11 12) ] [ text <| viewMaybeBigInt model.additionAnswer ] ]
                , bigBreak
                , div [] [ button [ onClick (MutateAdd contractAddress 42) ] [ text <| "Add 42 to someNum" ] ]
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

        Deployed { contractAddress, transactionHash } ->
            div []
                [ p []
                    [ text "Contract TxId: "
                    , a [ target "_blank", href ("https://ropsten.etherscan.io/tx/" ++ transactionHash) ] [ text transactionHash ]
                    ]
                , br [] []
                , p []
                    [ text "Contract Address: "
                    , a [ target "_blank", href ("https://ropsten.etherscan.io/address/" ++ contractAddress) ] [ text contractAddress ]
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
            div [] [ text address_ ]


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
    | WatchAddEvents
    | StopAddEvents
    | AddEvents (EventLog LightBox.AddArgs)
    | DeployContract
    | AddNumbers Address Int Int
    | MutateAdd Address Int
    | LatestResponse (Result Web3.Error Block)
    | LightBoxResponse (Result Web3.Error ContractInfo)
    | LightBoxAddResponse (Result Web3.Error BigInt)
    | LightBoxMutateAddResponse (Result Web3.Error TxId)
    | EventHandler (Result Web3.Error ())


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
                        { model | testData = "Twerked" } ! []

                    Err error ->
                        handleError model error

            WatchAddEvents ->
                model
                    ! [ Task.attempt EventHandler <|
                            LightBox.watchAdd
                                defaultFilterParams
                                LightBox.defaultAddFilter
                                "0xeb8f5983d099b0be3f78367bf5efccb5df9e3487"
                                LightBox.WatchAdd
                      ]

            AddEvents events ->
                { model | eventData = events :: model.eventData } ! []

            StopAddEvents ->
                model ! []

            DeployContract ->
                { model | contractInfo = Deploying }
                    ! [ Task.attempt LightBoxResponse <|
                            LightBox.new
                                (BigInt.fromString "502030200")
                                { someNum_ = BigInt.fromInt 13 }
                      ]

            AddNumbers address a b ->
                model
                    ! [ Task.attempt LightBoxAddResponse
                            (LightBox.add address a b)
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
                            (LightBox.mutateAdd address a)
                      ]

            LightBoxMutateAddResponse response ->
                case response of
                    Ok txId ->
                        { model | txIds = txId :: model.txIds } ! []

                    Err error ->
                        handleError model error

            EventHandler response ->
                case response of
                    Ok _ ->
                        model ! []

                    Err error ->
                        handleError model error


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ Port.watchAdd (LightBox.formatAddEventLog >> AddEvents) ]
