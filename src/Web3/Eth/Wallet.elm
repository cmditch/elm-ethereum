module Web3.Eth.Wallet
    exposing
        ( list
        , create
        , createMany
        , createWithEntropy
        , createManyWithEntropy
        , add
        , remove
        , clear
        , encrypt
        , decrypt
        , save
        , load
        , length
        , getByIndex
        , getKeys
        )

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (maybe)
import Dict exposing (Dict)
import Web3
import Web3.Internal as Internal
import Web3.Types exposing (..)
import Web3.Encoders exposing (encodeKeystoreList)
import Web3.Decoders
    exposing
        ( expectJson
        , expectInt
        , expectBool
        , accountDecoder
        , keystoreDecoder
        )


list : Task Error (Dict Int Account)
list =
    retryWalletLoad
        |> Task.andThen listWithKeys


create : Task Error (Dict Int Account)
create =
    createMany 1


createMany : Int -> Task Error (Dict Int Account)
createMany =
    createManyWithEntropy Nothing


createWithEntropy : String -> Task Error (Dict Int Account)
createWithEntropy entropy =
    createManyWithEntropy (Just entropy) 1


createManyWithEntropy : Maybe String -> Int -> Task Error (Dict Int Account)
createManyWithEntropy maybeEntropy count =
    let
        entropy =
            case maybeEntropy of
                Just entropy ->
                    [ Encode.string entropy ]

                Nothing ->
                    []
    in
        Internal.toTask
            { method = "eth.accounts.wallet.create"
            , params = Encode.list ([ Encode.int count ] ++ entropy)
            , expect = expectJson (Decode.succeed ())
            , callType = CustomSync "null"
            , applyScope = Just "web3.eth.accounts.wallet"
            }
            |> Task.andThen (\_ -> list)


add : PrivateKey -> Task Error ()
add (PrivateKey privateKey) =
    Internal.toTask
        { method = "eth.accounts.wallet.add"
        , params = Encode.list [ Encode.string privateKey ]
        , expect = expectJson (Decode.succeed ())
        , callType = CustomSync "null"
        , applyScope = Just "web3.eth.accounts.wallet"
        }


remove : WalletIndex -> Task Error Bool
remove index =
    let
        id =
            case index of
                AddressIndex (Address address) ->
                    address

                IntIndex int ->
                    toString int
    in
        Internal.toTask
            { method = "eth.accounts.wallet.remove"
            , params = Encode.list [ Encode.string id ]
            , expect = expectBool
            , callType = Sync
            , applyScope = Just "web3.eth.accounts.wallet"
            }


clear : Task Error (Dict Int Account)
clear =
    (Internal.toTask
        { method = "eth.accounts.wallet.clear"
        , params = Encode.list []
        , expect = expectJson (Decode.succeed ())
        , callType = CustomSync "null"
        , applyScope = Just "web3.eth.accounts.wallet"
        }
        |> Task.andThen (\_ -> list)
    )
        |> Web3.delayExecution


encrypt : String -> Task Error (List Keystore)
encrypt password =
    Internal.toTask
        { method = "eth.accounts.wallet.encrypt"
        , params = Encode.list [ Encode.string password ]
        , expect = expectJson (Decode.list keystoreDecoder)
        , callType = Sync
        , applyScope = Just "web3.eth.accounts.wallet"
        }
        |> Web3.delayExecution


decrypt : List Keystore -> String -> Task Error (Dict Int Account)
decrypt keystores password =
    (Internal.toTask
        { method = "eth.accounts.wallet.decrypt"
        , params = Encode.list [ encodeKeystoreList keystores, Encode.string password ]
        , expect = expectJson (Decode.succeed ())
        , callType = CustomSync "null"
        , applyScope = Just "web3.eth.accounts.wallet"
        }
        |> Task.andThen (\_ -> list)
    )
        |> Web3.delayExecution


save : String -> Task Error Bool
save password =
    Internal.toTask
        { method = "eth.accounts.wallet.save"
        , params = Encode.list [ Encode.string password ]
        , expect = expectBool
        , callType = Sync
        , applyScope = Just "web3.eth.accounts.wallet"
        }
        |> Web3.delayExecution


load : String -> Task Error ()
load password =
    (Internal.toTask
        { method = "eth.accounts.wallet.load"
        , params = Encode.list [ Encode.string password ]
        , expect = expectJson (Decode.succeed ())
        , callType = CustomSync "null"
        , applyScope = Just "web3.eth.accounts.wallet"
        }
    )
        |> Web3.delayExecution


length : Task Error Int
length =
    Internal.toTask
        { method = "eth.accounts.wallet.length"
        , params = Encode.list []
        , expect = expectInt
        , callType = Getter
        , applyScope = Nothing
        }


getByIndex : WalletIndex -> Task Error (Maybe Account)
getByIndex index =
    let
        id =
            case index of
                AddressIndex (Address address) ->
                    address

                IntIndex int ->
                    toString int
    in
        Internal.toTask
            { method = "eth.accounts.wallet[" ++ id ++ "]"
            , params = Encode.list []
            , expect = expectJson (maybe accountDecoder)
            , callType = Getter
            , applyScope = Nothing
            }



-- Internal


getKeys : Task Error (List Int)
getKeys =
    Internal.toTask
        { method = "eth.accounts.wallet._currentIndexes"
        , params = Encode.list []
        , expect = expectJson (Decode.list Decode.int)
        , callType = Sync
        , applyScope = Just "web3.eth.accounts.wallet"
        }


listWithKeys : List Int -> Task Error (Dict Int Account)
listWithKeys keys =
    let
        toTaskOFIndexAccountTuple : Int -> Task Error ( Int, Maybe Account )
        toTaskOFIndexAccountTuple index =
            getByIndex (IntIndex index)
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
        keys
            |> List.map toTaskOFIndexAccountTuple
            |> Task.sequence
            |> Task.map maybeAccountsToDictOfAccounts


retryWalletLoad : Task Error (List Int)
retryWalletLoad =
    let
        failIfEmpty keys =
            if List.isEmpty keys then
                Task.fail
                    (Error "Wallet empty")
            else
                Task.succeed keys
    in
        Web3.retry { sleep = 0.5, attempts = 10 } (getKeys |> Task.andThen failIfEmpty)
            |> Task.onError (\_ -> Task.succeed [])
