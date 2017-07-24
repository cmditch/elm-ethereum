module Main exposing (..)

import Task
import Html exposing (..)
import Html.Attributes exposing (href, target)
import Html.Events exposing (onClick, onInput)
import Web3 exposing (Error(..), toTask)
import Web3.Eth.Types exposing (Address, Block, TxId, NewContract)
import LightBox
import BigInt exposing (BigInt)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


type alias Model =
    { latestBlock : Maybe Block
    , contractInfo : DeployableContract
    , coinbase : Address
    , additionAnswer : Maybe BigInt
    , txIds : List TxId
    , error : List String
    }


init : ( Model, Cmd Msg )
init =
    { latestBlock = Nothing
    , contractInfo = UnDeployed
    , coinbase = "0xe87529a6123a74320e13a6dabf3606630683c029"
    , additionAnswer = Nothing
    , txIds = []
    , error = []
    }
        ! [{- TODO Web3.init command needed, for wallet check and web3 connection status -}]


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick DeployContract ] [ text "Touch web3 plz" ]
        , bigBreak
        , viewAddButton model
          -- , bigBreak
          -- , viewBlock model.latestBlock
        , bigBreak
        , viewContractInfo model.contractInfo
        , bigBreak
        , viewError model.error
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
        Deployed { address } ->
            div []
                [ text "You can call LightBox.add(11,12)"
                , div [] [ button [ onClick (AddNumbers address 11 12) ] [ text <| viewMaybeBigInt model.additionAnswer ] ]
                , bigBreak
                , div [] [ button [ onClick (MutateAdd address 23) ] [ text <| "Add 23 to someNum" ] ]
                , bigBreak
                , div [] [ text <| toString model.txIds ]
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

        Deployed { txId, address } ->
            div []
                [ p []
                    [ text "Contract TxId: "
                    , a [ target "_blank", href ("https://ropsten.etherscan.io/tx/" ++ txId) ] [ text txId ]
                    ]
                , br [] []
                , p []
                    [ text "Contract Address: "
                    , a [ target "_blank", href ("https://ropsten.etherscan.io/address/" ++ address) ] [ text address ]
                    ]
                ]

        ErrorDeploying ->
            div [] [ text "Error deploying contract." ]


type DeployableContract
    = UnDeployed
    | Deploying
    | Deployed NewContract
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
            span [] []

        _ ->
            div [] [ text <| toString error ]


type Msg
    = DeployContract
    | AddNumbers Address Int Int
    | MutateAdd Address Int
    | LatestResponse (Result Web3.Error Block)
    | LightBoxResponse (Result Web3.Error NewContract)
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
            DeployContract ->
                { model | contractInfo = Deploying }
                    ! [ Task.attempt LightBoxResponse
                            (LightBox.new
                                (BigInt.fromString "502030200")
                                { someNum_ = BigInt.fromInt 13 }
                            )
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
