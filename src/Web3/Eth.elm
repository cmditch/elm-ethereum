effect module Web3.Eth
    where { command = MyCmd, subscription = MySub }
    exposing
        ( getProtocolVersion
        , isSyncing
        , getCoinbase
        , isMining
        , getHashrate
        , getGasPrice
        , getAccounts
        , getBlockNumber
        , getBalance
        , getStorageAt
        , getStorageAtBlock
        , getCode
        , getCodeAtBlock
        , getBlockTransactionCount
        , getBlock
        , getBlockTxObjs
        , getBlockUncleCount
        , getUncle
        , getUncleTxObjs
        , getTransaction
        , getTransactionFromBlock
        , getTransactionReceipt
        , getTransactionCount
        , sendTransaction
        , sendSignedTransaction
        , sign
        , signTransaction
        , call
        , callAtBlock
        , estimateGas
        , getPastLogs
        , getId
        , isListening
        , getPeerCount
        , getNetworkType
        , currentProviderUrl
        )

{-| Web3.Eth
-}

import Web3.Internal as Internal exposing (CallType(..))
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Task exposing (Task)
import BigInt exposing (BigInt)
import Dict exposing (Dict)
import Process


getProtocolVersion : Task Error String
getProtocolVersion =
    Internal.toTask
        { method = "eth.getProtocolVersion"
        , params = Encode.list []
        , expect = expectString
        , callType = Async
        , applyScope = Nothing
        }


isSyncing : Task Error (Maybe SyncStatus)
isSyncing =
    Internal.toTask
        { method = "eth.isSyncing"
        , params = Encode.list []
        , expect = expectJson syncStatusDecoder
        , callType = Async
        , applyScope = Nothing
        }



{-
   isSyncing : Task Error (Maybe SyncStatus)
   Implement within Effect Manager.
   NOTE Doesn't seem to work within MetaMask!
-}


getCoinbase : Task Error Address
getCoinbase =
    Internal.toTask
        { method = "eth.getCoinbase"
        , params = Encode.list []
        , expect = expectJson addressDecoder
        , callType = Async
        , applyScope = Nothing
        }


isMining : Task Error Bool
isMining =
    Internal.toTask
        { method = "eth.isMining"
        , params = Encode.list []
        , expect = expectBool
        , callType = Async
        , applyScope = Nothing
        }


getHashrate : Task Error Int
getHashrate =
    Internal.toTask
        { method = "eth.getHashrate"
        , params = Encode.list []
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getGasPrice : Task Error BigInt
getGasPrice =
    Internal.toTask
        { method = "eth.getGasPrice"
        , params = Encode.list []
        , expect = expectBigInt
        , callType = Async
        , applyScope = Nothing
        }


getAccounts : Task Error (List Address)
getAccounts =
    Internal.toTask
        { method = "eth.getAccounts"
        , params = Encode.list []
        , expect = expectJson (Decode.list addressDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getBlockNumber : Task Error BlockId
getBlockNumber =
    Internal.toTask
        { method = "eth.getBlockNumber"
        , params = Encode.list []
        , expect = expectJson blockNumDecoder
        , callType = Async
        , applyScope = Nothing
        }


getBalance : Address -> Task Error BigInt
getBalance (Address address) =
    Internal.toTask
        { method = "eth.getBalance"
        , params = Encode.list [ Encode.string address ]
        , expect = expectBigInt
        , callType = Async
        , applyScope = Nothing
        }


getStorageAt : Address -> Int -> Task Error Hex
getStorageAt =
    getStorageAtBlock Latest


getStorageAtBlock : BlockId -> Address -> Int -> Task Error Hex
getStorageAtBlock blockId (Address address) position =
    Internal.toTask
        { method = "eth.getStorageAt"
        , params = Encode.list [ Encode.string address, Encode.int position, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


getCode : Address -> Task Error Hex
getCode =
    getCodeAtBlock Latest


getCodeAtBlock : BlockId -> Address -> Task Error Hex
getCodeAtBlock blockId (Address address) =
    Internal.toTask
        { method = "eth.getCode"
        , params = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


getBlockTransactionCount : BlockId -> Task Error (Maybe Int)
getBlockTransactionCount blockId =
    Internal.toTask
        { method = "eth.getBlockTransactionCount"
        , params = Encode.list [ getBlockIdValue blockId ]
        , expect = expectJson (Decode.maybe Decode.int)
        , callType = Async
        , applyScope = Nothing
        }


getBlock : BlockId -> Task Error (Maybe (Block TxId))
getBlock blockId =
    Internal.toTask
        { method = "eth.getBlock"
        , params = Encode.list [ getBlockIdValue blockId, Encode.bool False ]
        , expect = expectJson (Decode.maybe blockTxIdDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getBlockTxObjs : BlockId -> Task Error (Maybe (Block TxObj))
getBlockTxObjs blockId =
    Internal.toTask
        { method = "eth.getBlock"
        , params = Encode.list [ getBlockIdValue blockId, Encode.bool True ]
        , expect = expectJson (Decode.maybe blockTxObjDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getBlockUncleCount : BlockId -> Task Error (Maybe Int)
getBlockUncleCount blockId =
    Internal.toTask
        { method = "eth.getBlockUncleCount"
        , params = Encode.list [ getBlockIdValue blockId ]
        , expect = expectJson (Decode.maybe Decode.int)
        , callType = Async
        , applyScope = Nothing
        }


getUncle : BlockId -> Int -> Task Error (Maybe (Block TxId))
getUncle blockId index =
    Internal.toTask
        { method = "eth.getUncle"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool False ]
        , expect = expectJson (Decode.maybe blockTxIdDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getUncleTxObjs : BlockId -> Int -> Task Error (Maybe (Block TxObj))
getUncleTxObjs blockId index =
    Internal.toTask
        { method = "eth.getUncle"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index, Encode.bool True ]
        , expect = expectJson (Decode.maybe blockTxObjDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getTransaction : TxId -> Task Error (Maybe TxObj)
getTransaction (TxId txId) =
    Internal.toTask
        { method = "eth.getTransaction"
        , params = Encode.list [ Encode.string txId ]
        , expect = expectJson (Decode.maybe txObjDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getTransactionFromBlock : BlockId -> Int -> Task Error (Maybe TxObj)
getTransactionFromBlock blockId index =
    Internal.toTask
        { method = "eth.getTransactionFromBlock"
        , params = Encode.list [ getBlockIdValue blockId, Encode.int index ]
        , expect = expectJson (Decode.maybe txObjDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getTransactionReceipt : TxId -> Task Error (Maybe TxReceipt)
getTransactionReceipt (TxId txId) =
    Internal.toTask
        { method = "eth.getTransactionReceipt"
        , params = Encode.list [ Encode.string txId ]
        , expect = expectJson (Decode.maybe txReceiptDecoder)
        , callType = Async
        , applyScope = Nothing
        }


getTransactionCount : BlockId -> Address -> Task Error (Maybe Int)
getTransactionCount blockId (Address address) =
    Internal.toTask
        { method = "eth.getTransactionCount"
        , params = Encode.list [ Encode.string address, getBlockIdValue blockId ]
        , expect = expectJson (Decode.maybe Decode.int)
        , callType = Async
        , applyScope = Nothing
        }


sendTransaction : Address -> TxParams -> Task Error TxId
sendTransaction from txParams =
    Internal.toTask
        { method = "eth.sendTransaction"
        , params = Encode.list [ encodeTxParams (Just from) txParams ]
        , expect = expectJson txIdDecoder
        , callType = Async
        , applyScope = Nothing
        }


sendSignedTransaction : Hex -> Task Error TxId
sendSignedTransaction (Hex signedData) =
    Internal.toTask
        { method = "eth.sendSignedTransaction"
        , params = Encode.list [ Encode.string signedData ]
        , expect = expectJson txIdDecoder
        , callType = Async
        , applyScope = Nothing
        }


sign : Address -> Hex -> Task Error Hex
sign (Address address) (Hex data) =
    Internal.toTask
        { method = "eth.sign"
        , params = Encode.list [ Encode.string data, Encode.string address ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


signTransaction : Address -> TxParams -> Task Error SignedTx
signTransaction address txParams =
    Internal.toTask
        { method = "eth.signTransaction"
        , params =
            Encode.list
                [ encodeTxParams (Just address) txParams
                , Encode.string (addressToString address)
                ]
        , expect = expectJson rpcSignedTxDecoder
        , callType = Async
        , applyScope = Nothing
        }


call : Maybe Address -> TxParams -> Task Error Hex
call =
    callAtBlock Latest


callAtBlock : BlockId -> Maybe Address -> TxParams -> Task Error Hex
callAtBlock blockId from txParams =
    -- TODO Look into removing 'from' field from TxParams since it's optional all over.
    Internal.toTask
        { method = "eth.call"
        , params = Encode.list [ encodeTxParams from txParams, getBlockIdValue blockId ]
        , expect = expectJson hexDecoder
        , callType = Async
        , applyScope = Nothing
        }


estimateGas : TxParams -> Task Error Int
estimateGas txParams =
    Internal.toTask
        { method = "eth.estimateGas"
        , params = Encode.list [ encodeTxParams Nothing txParams ]
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getPastLogs : LogParams -> Task Error (List Log)
getPastLogs params =
    -- TODO Something wrong with this function in Web3
    Internal.toTask
        { method = "eth.getPastLogs"
        , params = Encode.list [ encodeFilterParams params ]
        , expect = expectJson (Decode.list logDecoder)
        , callType = Async
        , applyScope = Nothing
        }


{-| web3.eth.net methods
-}
getId : Task Error Int
getId =
    Internal.toTask
        { method = "eth.net.getId"
        , params = Encode.list []
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


isListening : Task Error Bool
isListening =
    Internal.toTask
        { method = "eth.net.isListening"
        , params = Encode.list []
        , expect = expectBool
        , callType = Async
        , applyScope = Nothing
        }


getPeerCount : Task Error Int
getPeerCount =
    Internal.toTask
        { method = "eth.net.getPeerCount"
        , params = Encode.list []
        , expect = expectInt
        , callType = Async
        , applyScope = Nothing
        }


getNetworkType : Task Error Network
getNetworkType =
    Internal.toTask
        { method = "eth.net.getNetworkType"
        , params = Encode.list []
        , expect = expectJson networkTypeDecoder
        , callType = Async
        , applyScope = Nothing
        }


currentProviderUrl : Task Error String
currentProviderUrl =
    Internal.toTask
        { method = "eth.currentProvider.connection.url"
        , params = Encode.list []
        , expect = expectString
        , callType = Getter
        , applyScope = Nothing
        }



-- Effect Manager
-- type Subscription
--     = PendingTxs
--     | NewBlocks
--     | Syncing
--     | Logs LogParams
--
-- MANAGER COMMANDS


type MyCmd msg
    = Subscribe Subscription
    | Unsubscribe Subscription
    | ClearSubscriptions


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap _ cmd =
    case cmd of
        Subscribe subType ->
            Subscribe subType

        Unsubscribe eventId ->
            Unsubscribe eventId

        ClearSubscriptions ->
            ClearSubscriptions


subscribe : Subscription -> Cmd msg
subscribe subType =
    command <| Subscribe subType


unsubscribe : Subscription -> Cmd msg
unsubscribe subType =
    command <| Unsubscribe subType


clearSubscriptions : Cmd msg
clearSubscriptions =
    command ClearSubscriptions



-- MANAGER SUBSCRIPTIONS


type MySub msg
    = SubSentry Subscription (String -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap tagger (SubSentry subType toMsg) =
    SubSentry subType (toMsg >> tagger)


subSentry : Subscription -> (String -> msg) -> Sub msg
subSentry subType toMsg =
    subscription <| SubSentry subType toMsg



-- MANAGER


type EventEmitter
    = EventEmitter


type alias State msg =
    { subs : SubsDict msg
    , eventEmitters : EventEmitterDict
    }


type alias SubsDict msg =
    Dict.Dict String (List (String -> msg))


type alias EventEmitterDict =
    Dict.Dict String EventEmitter


init : Task Never (State msg)
init =
    Task.succeed (State Dict.empty Dict.empty)


(&>) : Task a x -> Task a b -> Task a b
(&>) t1 t2 =
    t1 |> Task.andThen (\_ -> t2)


onEffects : Platform.Router msg Msg -> List (MyCmd msg) -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router cmds subs state =
    let
        sendMessages =
            sendMessagesHelp router cmds state.eventEmitters

        newSubs =
            buildSubsDict subs Dict.empty
    in
        sendMessages
            |> Task.andThen (\newEventEmitters -> State newSubs newEventEmitters |> Task.succeed)


sendMessagesHelp : Platform.Router msg Msg -> List (MyCmd msg) -> EventEmitterDict -> Task Never EventEmitterDict
sendMessagesHelp router cmds eventEmittersDict =
    case cmds of
        _ ->
            Task.succeed eventEmittersDict



-- (Subscribe abi eventName address eventId) :: rest ->
--     case Dict.get eventId eventEmittersDict of
--         Just _ ->
--             sendMessagesHelp router rest eventEmittersDict
--
--         Nothing ->
--             createEventEmitter abi address eventName
--                 |> Task.andThen
--                     (\eventEmitter ->
--                         (Process.spawn (eventSubscribe router eventEmitter eventId))
--                             &> Task.succeed (Dict.insert eventId eventEmitter eventEmittersDict)
--                     )
--                 |> Task.andThen (\newEventEmitters -> sendMessagesHelp router rest newEventEmitters)
--
-- (Unsubscribe eventId) :: rest ->
--     case Dict.get eventId eventEmittersDict of
--         Just eventEmitter ->
--             Process.spawn (eventUnsubscribe eventEmitter)
--                 &> Task.succeed (Dict.remove eventId eventEmittersDict)
--
--         Nothing ->
--             sendMessagesHelp router rest eventEmittersDict
--
{-

   web3.eth.subscribe("pendingTransactions")
   web3.eth.subscribe("newBlockHeaders")
   web3.eth.subscribe("syncing")
   web3.eth.subscribe("logs", options)

-}


createEventEmitter : String -> String -> String -> Task Never EventEmitter
createEventEmitter abi address eventName =
    Native.Web3.createEventEmitter abi address eventName


eventSubscribe : Platform.Router msg Msg -> EventEmitter -> String -> Task Never ()
eventSubscribe router eventEmitter eventId =
    Native.Web3.eventSubscribe
        eventEmitter
        (\log -> Platform.sendToSelf router (RecieveLog eventId log))


eventUnsubscribe : EventEmitter -> Task Never ()
eventUnsubscribe eventEmitter =
    Native.Web3.eventUnsubscribe eventEmitter


buildSubsDict : List (MySub msg) -> SubsDict msg -> SubsDict msg
buildSubsDict subs dict =
    case subs of
        _ ->
            dict



-- (EventSentry eventId toMsg) :: rest ->
--     buildSubsDict rest (Dict.update eventId (add toMsg) dict)


add : a -> Maybe (List a) -> Maybe (List a)
add value maybeList =
    case maybeList of
        Nothing ->
            Just [ value ]

        Just list ->
            Just (value :: list)


type Msg
    = RecieveLog String String


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router (RecieveLog eventId log) state =
    let
        sends =
            Dict.get eventId state.subs
                |> Maybe.withDefault []
                |> List.map (\tagger -> Platform.sendToApp router (tagger log))
    in
        Process.spawn (Task.sequence sends) &> Task.succeed state
