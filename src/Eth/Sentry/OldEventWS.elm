module Eth.Sentry.Event exposing (temp)

-- ( EventSentry, Msg, FilterKey
-- , init, update, changeNode, listen, withDebug
-- , watch, watchOnce, unWatch, toFilterKey
-- , newBlocks, unWatchNewBlocks, nextBlock
-- , pendingTxs, unWatchPendingTxs
-- )
{- Listen to contract events, and other chain activity


   # Types

   @docs EventSentry, Msg, FilterKey


   # Core

   @docs init, update, changeNode, listen, withDebug


   # Contract Events/Logs

   @docs watch, watchOnce, unWatch, toFilterKey


   # Blocks

   @docs newBlocks, unWatchNewBlocks, nextBlock


   # Pending Transactions

   @docs pendingTxs, unWatchPendingTxs

-}
-- import Legacy.WebSocket as WS

import BigInt
import Dict exposing (Dict)
import Eth.Decode as Decode
import Eth.Defaults as Default
import Eth.Encode as Encode
import Eth.RPC as RPC
import Eth.Types exposing (..)
import Eth.Utils as U exposing (addressToString, keccak256)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Task


temp =
    1



{--Internal Docs

    Design inspiration taken from elm-phoenix-sockets, thanks!!!

    -- Glossary --

    RpcId           - JSON RPC request ID, mapped to various things internally
    SubscriptionId  - eth_subscribe filter id, e.g., "0xca4b1e6c2973ec643a6e63c459ec1e13", needed for eth_unsubscribe
    FilterKey       - Dict Key which allows the user to open/close subscriptions.
                        Generated automatically with "getHeads" and "getPendingTransactions" calls.
                        Generated from the LogFilter params in the case of "logs" call. User must keep track of LogFilter in order to close it.

    -- EventSentry Workflow --

    1. User calls (EventSentry.watch myFilterLog), Cmd.maps and fires off assoicated Cmd
        and updates their model.eventSentry with the newly returned sentry.

    2. The returned EventSentry includes new mappings for (RpcId -> FilterKey) and (FilterKey -> FilterState). This allows:
        a) The EventSentry to update the FilterState with it's SubscriptionId once the eth_node responds.
        b) The EventSentry to route the appropriate eth_node responses to the user app with an onRecieve tagger (Value -> msg).
        b) The user to close a subscription.

    3. Once the eth_node responds with a "Subscription Opened" message, a (SubscriptionId -> FilterKey) mapping is updated.

    4a. Further incoming msgs from the eth_node include it's SubscriptionId and data.
        The data is routed to the user app through the "teach me how to msg" tagger function
        provided by the user on the initial EventSentry.watch call

    4b. The tagger is found by going through a series of Dict.gets from (SubscriptionId -> FilterKey -> FilterState -> tagger)

    5.  The user closes the subscription by providing EventSentry.unWatch with the initial FilterKey,
        where (FilterKey -> FilterState -> SubscriptionId) is provided to an eth_unsubscribe RPC call.


-}
-- type EventSentry msg
--     = EventSentry
--         { nodePath : String
--         , tagger : Msg -> msg
--         , filters : Dict FilteryKeyInternal (FilterState msg)
--         , rpcIdToFKey : Dict RpcId FilterKey
--         , subIdToFKey : Dict SubscriptionId FilterKey
--         , ref : RpcId
--         -- , debug : Bool
--         }
-- {-| -}
-- init : ( OutPort, InPort ) -> (Msg -> msg) -> WebsocketProvider -> EventSentry msg
-- init tagger nodePath =
--     EventSentry
--         { nodePath = nodePath
--         , tagger = tagger
--         , filters = Dict.empty
--         , rpcIdToFKey = Dict.empty
--         , subIdToFKey = Dict.empty
--         , ref = 1
--         -- , debug = False
--         }
-- {-| -}
-- listen : EventSentry msg -> Sub msg
-- listen (EventSentry sentry) =
--     WS.listen sentry.nodePath (nodeResponseToMsg sentry.debug << decodeMessage)
--         |> Sub.map sentry.tagger
-- {-| -}
-- listen : (Value -> Cmd msg) -> EventSentry msg -> Cmd msg
-- listen cmdPort (EventSentry sentry) =
--     WS.makeOpen sentry.nodePath
--         -- (nodeResponseToMsg sentry.debug << decodeMessage)
--         |> WS.send cmdPort
-- {-| -}
-- watch : (Value -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg )
-- watch onReceive sentry logFilter =
--     watch_ False [ Encode.string "logs", Encode.logFilter logFilter ] onReceive sentry (toFilterKey logFilter)
-- -- watch_ : Bool -> List Value -> (Value -> msg) -> EventSentry msg -> FilterKey -> ( EventSentry msg, Cmd msg )
-- {-| -}
-- watchOnce : (Value -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg )
-- watchOnce onReceive sentry logFilter =
--     watch_ True [ Encode.string "logs", Encode.logFilter logFilter ] onReceive sentry (toFilterKey logFilter)
-- {-| -}
-- unWatch : EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg )
-- unWatch sentry logFilter =
--     unWatch_ sentry (toFilterKey logFilter)
-- {-| -}
-- newBlocks : (BlockHead -> msg) -> EventSentry msg -> ( EventSentry msg, Cmd msg )
-- newBlocks onReceive sentry =
--     watch_ False [ Encode.string "newHeads" ] (decodeBlockHead >> onReceive) sentry newBlockHeadsKey
-- {-| -}
-- nextBlock : (BlockHead -> msg) -> EventSentry msg -> ( EventSentry msg, Cmd msg )
-- nextBlock onReceive sentry =
--     watch_ True [ Encode.string "newHeads" ] (decodeBlockHead >> onReceive) sentry newBlockHeadsKey
-- {-| -}
-- unWatchNewBlocks : EventSentry msg -> ( EventSentry msg, Cmd msg )
-- unWatchNewBlocks sentry =
--     unWatch_ sentry newBlockHeadsKey
-- {-| -}
-- pendingTxs : (TxHash -> msg) -> EventSentry msg -> ( EventSentry msg, Cmd msg )
-- pendingTxs onReceive sentry =
--     watch_ False [ Encode.string "newPendingTransactions" ] (decodeTxHash >> onReceive) sentry pendingTxsKey
-- {-| -}
-- unWatchPendingTxs : EventSentry msg -> ( EventSentry msg, Cmd msg )
-- unWatchPendingTxs sentry =
--     unWatch_ sentry pendingTxsKey
-- {-| -}
-- withDebug : EventSentry msg -> EventSentry msg
-- withDebug (EventSentry sentry) =
--     EventSentry { sentry | debug = True }
-- {-| -}
-- changeNode : String -> EventSentry msg -> EventSentry msg
-- changeNode newNodePath (EventSentry eventSentry) =
--     EventSentry { eventSentry | nodePath = newNodePath }
-- {-| (Contract Address, Event Topic)
-- Need to come up with a better Key scheme to avoid collisions
-- Maybe by hashing the Filter params
-- -}
-- type FilterKey
--     = FilterKey FilteryKeyInternal
-- type alias FilteryKeyInternal =
--     ( String, String )
-- {-| -}
-- toFilterKey : LogFilter -> FilterKey
-- toFilterKey { address, topics } =
--     let
--         eventTopic =
--             List.head topics
--                 |> Maybe.andThen identity
--                 |> Maybe.map U.hexToString
--                 |> Maybe.withDefault ""
--     in
--     FilterKey ( addressToString address, eventTopic )
-- type alias RpcId =
--     Int
-- -- Internal
-- watch_ : Bool -> List Value -> (Value -> msg) -> EventSentry msg -> FilterKey -> ( EventSentry msg, Cmd msg )
-- watch_ isOnce rpcParams onReceive ((EventSentry sentry) as sentry_) (FilterKey filterKey) =
--     case Dict.get filterKey sentry.filters of
--         Nothing ->
--             ( EventSentry
--                 { sentry
--                     | filters = Dict.insert filterKey (makeFilter isOnce onReceive sentry.ref) sentry.filters
--                     , rpcIdToFKey = Dict.insert sentry.ref (FilterKey filterKey) sentry.rpcIdToFKey
--                     , ref = sentry.ref + 1
--                 }
--             , WS.send sentry.nodePath (openFilterRpc sentry.ref rpcParams)
--             )
--         Just _ ->
--             ( sentry_, Cmd.none )
-- unWatch_ : EventSentry msg -> FilterKey -> ( EventSentry msg, Cmd msg )
-- unWatch_ ((EventSentry sentry) as sentry_) (FilterKey filterKey) =
--     case Dict.get filterKey sentry.filters of
--         Nothing ->
--             ( sentry_, Cmd.none )
--         Just filterState ->
--             case filterState.subId of
--                 Just subId ->
--                     let
--                         _ =
--                             debugHelp sentry log.subClosed { rpcId = filterState.rpcId, subId = subId }
--                     in
--                     ( EventSentry
--                         { sentry
--                             | filters = Dict.remove filterKey sentry.filters
--                             , rpcIdToFKey = Dict.remove filterState.rpcId sentry.rpcIdToFKey
--                             , subIdToFKey = Dict.remove subId sentry.subIdToFKey
--                             , ref = sentry.ref + 1
--                         }
--                     , WS.send sentry.nodePath (closeFilterRpc sentry.ref subId)
--                     )
--                 Nothing ->
--                     ( sentry_, Cmd.none )
-- -- Types
-- type NodeResponse
--     = Subscribed OpenedMsg
--     | Event EventMsg
--     | Unsubscribed ClosedMsg
-- type alias OpenedMsg =
--     { rpcId : RpcId, subId : SubscriptionId }
-- type alias ClosedMsg =
--     { rpcId : RpcId, result : Bool }
-- type alias EventMsg =
--     { method : String
--     , params : { subId : SubscriptionId, result : Value }
--     }
-- type alias SubscriptionId =
--     String
-- type FilterStatus
--     = Opening
--     | Opened
-- type alias FilterState msg =
--     { tagger : Value -> msg
--     , status : FilterStatus
--     , rpcId : RpcId
--     , subId : Maybe SubscriptionId
--     , once : Bool
--     }
-- --- UPDATE
-- {-| -}
-- type Msg
--     = NoOp
--     | SubscriptionOpened OpenedMsg
--     | CloseSubscription FilterKey
--     | SubscriptionClosed ClosedMsg
--     | EventReceived EventMsg
-- {-| -}
-- update : Msg -> EventSentry msg -> ( EventSentry msg, Cmd msg )
-- update msg ((EventSentry sentry) as sentry_) =
--     case msg of
--         SubscriptionOpened openedMsg ->
--             case getFilterByRpcId openedMsg.rpcId sentry_ of
--                 Just ( FilterKey filterKey, filterState ) ->
--                     ( EventSentry
--                         { sentry
--                             | filters =
--                                 Dict.update filterKey
--                                     (Maybe.map (setFilterStateOpened openedMsg.subId))
--                                     sentry.filters
--                             , subIdToFKey =
--                                 Dict.insert openedMsg.subId
--                                     (FilterKey filterKey)
--                                     sentry.subIdToFKey
--                         }
--                     , Cmd.none
--                     )
--                 Nothing ->
--                     ( sentry_, Cmd.none )
--         CloseSubscription filterKey ->
--             unWatch_ sentry_ filterKey
--         SubscriptionClosed closedMsg ->
--             ( sentry_, Cmd.none )
--         EventReceived eventMsg ->
--             let
--                 result =
--                     eventMsg.params.result
--                 subId =
--                     eventMsg.params.subId
--             in
--             case getFilterBySubscriptionId subId sentry_ of
--                 Just ( FilterKey filterKey, filterState, True ) ->
--                     ( EventSentry
--                         { sentry
--                             | filters = Dict.remove filterKey sentry.filters
--                             , rpcIdToFKey = Dict.remove filterState.rpcId sentry.rpcIdToFKey
--                             , subIdToFKey = Dict.remove subId sentry.subIdToFKey
--                             , ref = sentry.ref + 1
--                         }
--                     , Cmd.batch
--                         [ Task.perform filterState.tagger (Task.succeed result)
--                         , WS.send sentry.nodePath (closeFilterRpc sentry.ref subId)
--                         ]
--                     )
--                 Just ( filterKey, filterState, False ) ->
--                     ( sentry_, Task.perform filterState.tagger (Task.succeed result) )
--                 Nothing ->
--                     ( sentry_, Cmd.none )
--         NoOp ->
--             ( sentry_, Cmd.none )
-- nodeResponseToMsg : Bool -> Maybe NodeResponse -> Msg
-- nodeResponseToMsg debug mNodeResponse =
--     let
--         _ =
--             if debug then
--                 Debug.log "EventSentry" mNodeResponse
--             else
--                 mNodeResponse
--     in
--     case mNodeResponse of
--         Just (Event eventMsg) ->
--             EventReceived eventMsg
--         Just (Subscribed openedMsg) ->
--             SubscriptionOpened openedMsg
--         Just (Unsubscribed closedMsg) ->
--             NoOp
--         Nothing ->
--             NoOp
-- -- Dict Helpers
-- getFilterByRpcId : RpcId -> EventSentry msg -> Maybe ( FilterKey, FilterState msg )
-- getFilterByRpcId rpcId (EventSentry sentry) =
--     Dict.get rpcId sentry.rpcIdToFKey
--         |> Maybe.andThen
--             (\(FilterKey key) ->
--                 Dict.get key sentry.filters
--                     |> Maybe.map (\f -> ( FilterKey key, f ))
--             )
-- getFilterBySubscriptionId : SubscriptionId -> EventSentry msg -> Maybe ( FilterKey, FilterState msg, Bool )
-- getFilterBySubscriptionId fId (EventSentry sentry) =
--     Dict.get fId sentry.subIdToFKey
--         |> Maybe.andThen
--             (\(FilterKey key) ->
--                 Dict.get key sentry.filters
--                     |> Maybe.map (\f -> ( FilterKey key, f, f.once ))
--             )
-- -- Filter Helpers
-- makeFilter : Bool -> (Value -> msg) -> RpcId -> FilterState msg
-- makeFilter isOnce onReceive rpcId =
--     { tagger = onReceive
--     , status = Opening
--     , rpcId = rpcId
--     , subId = Nothing
--     , once = isOnce
--     }
-- setFilterStateOpened : SubscriptionId -> FilterState msg -> FilterState msg
-- setFilterStateOpened subId filterState =
--     { filterState | status = Opened, subId = Just subId }
-- -- RPC Helpers
-- openFilterRpc : RpcId -> List Value -> String
-- openFilterRpc rpcId rpcParams =
--     RPC.encode rpcId "eth_subscribe" rpcParams
--         |> Encode.encode 0
-- closeFilterRpc : RpcId -> String -> String
-- closeFilterRpc rpcId filterId =
--     RPC.encode rpcId "eth_unsubscribe" [ Encode.string filterId ]
--         |> Encode.encode 0
-- -- Decoders
-- decodeMessage : String -> Maybe NodeResponse
-- decodeMessage =
--     Result.toMaybe << Decode.decodeString nodeResponseDecoder
-- nodeResponseDecoder : Decoder NodeResponse
-- nodeResponseDecoder =
--     Decode.oneOf
--         [ openedMsgDecoder
--         , eventDecoder
--         , closedMsgDecoder
--         ]
-- openedMsgDecoder : Decoder NodeResponse
-- openedMsgDecoder =
--     Decode.map Subscribed <|
--         Decode.map2 OpenedMsg
--             (Decode.field "id" Decode.int)
--             (Decode.field "result" Decode.string)
-- closedMsgDecoder : Decoder NodeResponse
-- closedMsgDecoder =
--     Decode.map Unsubscribed <|
--         Decode.map2 ClosedMsg
--             (Decode.field "id" Decode.int)
--             (Decode.field "result" Decode.bool)
-- eventDecoder : Decoder NodeResponse
-- eventDecoder =
--     let
--         eventParamsDecoder =
--             Decode.map2 (\s r -> { subId = s, result = r })
--                 (Decode.field "subscription" Decode.string)
--                 (Decode.field "result" Decode.value)
--     in
--     Decode.map Event <|
--         Decode.map2 EventMsg
--             (Decode.field "method" Decode.string)
--             (Decode.field "params" eventParamsDecoder)
-- decodeBlockHead : Value -> BlockHead
-- decodeBlockHead val =
--     case Decode.decodeValue Decode.blockHead val of
--         Ok blockHead ->
--             blockHead
--         Err error ->
--             Debug.log error defaultBlockHead
-- decodeTxHash : Value -> TxHash
-- decodeTxHash val =
--     case Decode.decodeValue Decode.txHash val of
--         Ok txHash ->
--             txHash
--         Err error ->
--             Debug.log error Default.emptyTxHash
-- -- Constants
-- pendingTxsKey : FilterKey
-- pendingTxsKey =
--     FilterKey ( "pending", "txs" )
-- newBlockHeadsKey : FilterKey
-- newBlockHeadsKey =
--     FilterKey ( "new", "heads" )
-- debugHelp sentry logText val =
--     if sentry.debug then
--         Debug.log ("EventSentry - " ++ logText) val
--     else
--         val
-- log =
--     { subOpened = "Subscription Opened"
--     , subClosed = "Subscription Closed"
--     }
-- -- Default helpers
-- defaultBlockHead : BlockHead
-- defaultBlockHead =
--     { number = 42
--     , hash = Default.emptyBlockHash
--     , parentHash = Default.emptyBlockHash
--     , nonce = "open up a github issue on elm-ethereum, you should not see this, the shape of a blockhead must've changed"
--     , sha3Uncles = "open up a github issue on elm-ethereum, you should not see this, the shape of a blockhead must've changed"
--     , logsBloom = "open up a github issue on elm-ethereum, you should not see this, the shape of a blockhead must've changed"
--     , transactionsRoot = "open up a github issue on elm-ethereum, you should not see this, the shape of a blockhead must've changed"
--     , stateRoot = "open up a github issue on elm-ethereum, you should not see this, the shape of a blockhead must've changed"
--     , receiptsRoot = "open up a github issue on elm-ethereum, you should not see this, the shape of a blockhead must've changed"
--     , miner = Default.zeroAddress
--     , difficulty = BigInt.fromInt 0
--     , extraData = "open up a github issue on elm-ethereum, you should not see this, the shape of a blockhead must've changed"
--     , gasLimit = 0
--     , gasUsed = 0
--     , mixHash = "open up a github issue on elm-ethereum, you should not see this, the shape of a blockhead must've changed"
--     , timestamp = 0
--     }
