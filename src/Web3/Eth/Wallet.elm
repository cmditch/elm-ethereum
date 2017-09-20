module Web3.Eth.Wallet
    exposing
        ( create
        , createMany
        , load
        , count
        , getByIndex
        , list
        )

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (maybe)
import Web3 exposing (toTask, retryThrice)
import Dict exposing (Dict)
import Web3.Types exposing (..)
import Web3.Decoders exposing (expectJson, expectInt, expectBool, accountDecoder)
import Web3.Internal exposing (unfoldr)


create : Maybe String -> Task Error Account
create =
    createMany 1


createMany : Int -> Maybe String -> Task Error Account
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
            , expect = expectJson accountDecoder
            , callType = Sync
            , applyScope = Nothing
            }


load : String -> Task Error ()
load password =
    Web3.toTask
        { method = "eth.accounts.wallet.load"
        , params = Encode.list [ Encode.string password ]
        , expect = expectJson (Decode.succeed ())
        , callType = CustomSync "null"
        , applyScope = Just "web3.eth.accounts.wallet"
        }


list : String -> Task Error (Dict Int Account)
list password =
    let
        waitToLoad count =
            if count == 0 then
                Task.fail (Error "Error: Zero wallets loaded, try increasing retry time to allow longer decryption")
            else
                Task.succeed count
    in
        load password
            |> Task.andThen (\_ -> count)
            |> Task.andThen (waitToLoad >> retryThrice)
            |> Task.andThen listByInt


count : Task Error Int
count =
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


listByInt : Int -> Task Error (Dict Int Account)
listByInt count =
    let
        countUpFrom : Int -> List Int
        countUpFrom =
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
        countUpFrom (count - 1)
            |> List.map toTaskOFIndexAccountTuple
            |> Task.sequence
            |> Task.map maybeAccountsToDictOfAccounts
