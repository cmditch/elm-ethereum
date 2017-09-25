module Web3.Eth.Wallet
    exposing
        ( create
        , createWithEntropy
        , createMany
        , save
        , load
        , list
        , length
        , getByIndex
        , listThisMany
        )

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (maybe)
import Dict exposing (Dict)
import Web3 exposing (toTask, retryThrice)
import Web3.Types exposing (..)
import Web3.Decoders exposing (expectJson, expectInt, expectBool, accountDecoder)
import Web3.Internal exposing (unfoldr)


-- add
-- remove
-- save
-- encrypt
-- decrypt
-- clear


create : Task Error (Dict Int Account)
create =
    createMany 1 Nothing


createWithEntropy : String -> Task Error (Dict Int Account)
createWithEntropy entropy =
    createMany 1 (Just entropy)


createMany : Int -> Maybe String -> Task Error (Dict Int Account)
createMany count maybeEntropy =
    let
        entropy =
            case maybeEntropy of
                Just entropy ->
                    [ Encode.string entropy ]

                Nothing ->
                    []
    in
        Web3.toTask
            { method = "eth.accounts.wallet.create"
            , params = Encode.list ([ Encode.int count ] ++ entropy)
            , expect = expectJson (Decode.succeed ())
            , callType = CustomSync "null"
            , applyScope = Just "web3.eth.accounts.wallet"
            }
            |> Task.andThen (\_ -> list)


add : PrivateKey -> Task Error (Dict Int Account)
add (PrivateKey privateKey) =
    Web3.toTask
        { method = "eth.accounts.wallet.add"
        , params = Encode.list [ Encode.string privateKey ]
        , expect = expectJson (Decode.succeed ())
        , callType = CustomSync "null"
        , applyScope = Just "web3.eth.accounts.wallet"
        }
        |> Task.andThen (\_ -> list)


save : String -> Task Error Bool
save password =
    Web3.toTask
        { method = "eth.accounts.wallet.save"
        , params = Encode.list [ Encode.string password ]
        , expect = expectBool
        , callType = Sync
        , applyScope = Just "web3.eth.accounts.wallet"
        }
        |> Web3.delayExecution


load : String -> Task Error (Dict Int Account)
load password =
    (Web3.toTask
        { method = "eth.accounts.wallet.load"
        , params = Encode.list [ Encode.string password ]
        , expect = expectJson (Decode.succeed ())
        , callType = CustomSync "null"
        , applyScope = Just "web3.eth.accounts.wallet"
        }
        |> Task.andThen (\_ -> list)
    )
        |> Web3.delayExecution


list : Task Error (Dict Int Account)
list =
    retryWalletLoad
        |> Task.andThen listThisMany


length : Task Error Int
length =
    Web3.toTask
        { method = "eth.accounts.wallet.length"
        , params = Encode.list []
        , expect = expectInt
        , callType = Getter
        , applyScope = Nothing
        }


getByIndex : Int -> Task Error (Maybe Account)
getByIndex index =
    Web3.toTask
        { method = "eth.accounts.wallet[" ++ toString index ++ "]"
        , params = Encode.list []
        , expect = expectJson (maybe accountDecoder)
        , callType = Getter
        , applyScope = Nothing
        }



-- Internal


listThisMany : Int -> Task Error (Dict Int Account)
listThisMany walletLength =
    let
        countDownFrom : Int -> List Int
        countDownFrom =
            unfoldr
                (\n ->
                    if n < 0 then
                        Nothing
                    else
                        Just ( n, n - 1 )
                )

        toTaskOFIndexAccountTuple : Int -> Task Error ( Int, Maybe Account )
        toTaskOFIndexAccountTuple index =
            getByIndex index
                |> Task.map (\account -> ( index, account ))

        filterMaybes : ( Int, Maybe Account ) -> List ( Int, Account ) -> List ( Int, Account )
        filterMaybes ( index, maybeAccount ) accum =
            case maybeAccount of
                Just account ->
                    ( index, account ) :: accum

                Nothing ->
                    accum

        maybeAccountsToDictOfAccounts : List ( Int, Maybe Account ) -> Dict Int Account
        maybeAccountsToDictOfAccounts =
            Dict.fromList << List.foldl filterMaybes []
    in
        countDownFrom (walletLength - 1)
            |> List.map toTaskOFIndexAccountTuple
            |> Task.sequence
            |> Task.map maybeAccountsToDictOfAccounts


retryWalletLoad : Task Error Int
retryWalletLoad =
    let
        failIfZero count =
            if count == 0 then
                Task.fail
                    (Error "Wallet empty")
            else
                Task.succeed count
    in
        Web3.retry { sleep = 0.5, attempts = 10 } (length |> Task.andThen failIfZero)
            |> Task.onError (\_ -> Task.succeed 0)
