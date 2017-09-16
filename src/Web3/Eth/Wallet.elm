module Web3.Eth.Wallet exposing (..)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (maybe)
import Web3 exposing (toTask)
import Dict exposing (Dict)
import Web3.Types exposing (..)
import Web3.Decoders exposing (expectJson, expectInt, accountDecoder)


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


count : Task Error Int
count =
    Web3.toTask
        { method = "eth.accounts.wallet"
        , params = Encode.list []
        , expect = expectInt
        , callType = CustomSync "response.length"
        , applyScope = Nothing
        }


getByIndex : Int -> Task Error (Maybe Account)
getByIndex index =
    Web3.toTask
        { method = "eth.accounts.wallet"
        , params = Encode.list []
        , expect = expectJson (maybe accountDecoder)
        , callType = CustomSync ("response[" ++ toString index ++ "]")
        , applyScope = Nothing
        }


list : Int -> Task Error (Dict Int Account)
list count =
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


unfoldr : (b -> Maybe ( a, b )) -> b -> List a
unfoldr f seed =
    case f seed of
        Nothing ->
            []

        Just ( a, b ) ->
            a :: unfoldr f b
