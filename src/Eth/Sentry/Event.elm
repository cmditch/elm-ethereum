module Eth.Sentry.Event exposing
    ( EventSentry, Msg, Ref, init, stopWatching, update, watch, watchOnce
    , currentBlock
    )

{-| Event Sentry - HTTP Style - Polling ftw

@docs EventSentry, Msg, Ref, init, stopWatching, update, watch, watchOnce
@docs currentBlock

-}

import Dict exposing (Dict)
import Eth
import Eth.Types exposing (..)
import Http
import Maybe.Extra
import Process
import Set exposing (Set)
import Task exposing (Task)



{-
   HTTP Polling Event Sentry - How it works:
       Upon EventySentry initialization, the block number is polled every 2 seconds.

       When you want to watch for a particular event, it is added to a set of events to be watched for (`watching`).
       When a new block is mined, we check to see if it contains any events we are interested in watching.

      If any watches/requests are made before a block-number is found, the requests are marked as pending,
      and requested once a block-number is received.


   Note: We do not use eth_newFilter, or any of the filter RPC endpoints,
         as these are not supported by Infura (in favor of websockets).

-}
{-

   nodePath : HTTP Address of Ethereum Node
   tagger : Wrap an Sentry.Event.Msg in your applications Msg
   requests : Dictionary to keep track of user's event requests
   ref : RPC ID Reference
   blockNumber : The last known block number - `Nothing` if response to first block number request is yet to come.
   watching : List of events currently being watched for.
   pending : List of events to be requested once the sentry.blockNumber is received.
   errors : Any HTTP errors made during RPC calls.
-}


{-| -}
type EventSentry msg
    = EventSentry
        { nodePath : HttpProvider
        , tagger : Msg -> msg
        , requests : Dict Ref (RequestState msg)
        , ref : Ref
        , blockNumber : Maybe Int
        , watching : Set Int
        , pending : Set Int
        , errors : List Http.Error
        }


{-| -}
init : (Msg -> msg) -> HttpProvider -> ( EventSentry msg, Cmd msg )
init tagger nodePath =
    ( EventSentry
        { nodePath = nodePath
        , tagger = tagger
        , requests = Dict.empty
        , ref = 1
        , blockNumber = Nothing
        , watching = Set.empty
        , pending = Set.empty
        , errors = []
        }
    , Task.attempt (BlockNumber >> tagger) (Eth.getBlockNumber nodePath)
    )


{-| Returns the first log found.

If a block range is defined in the LogFilter,
this will only return the first log found within that given block range.

-}
watchOnce : (Log -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg )
watchOnce onReceive eventSentry logFilter =
    watch_ True onReceive eventSentry logFilter
        |> (\( eventSentry_, cmd, _ ) -> ( eventSentry_, cmd ))


{-| Continuously polls for logs in newly mined blocks.

If the range within the LogFilter includes past blocks,
then all events within the given block range are returned,
along with events in the latest block.

Polling continues until `stopWatching` is called.

-}
watch : (Log -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg, Ref )
watch =
    watch_ False


{-| -}
stopWatching : Ref -> EventSentry msg -> EventSentry msg
stopWatching ref (EventSentry sentry) =
    EventSentry { sentry | watching = Set.remove ref sentry.watching }


{-| The Event Sentry polls for the latest block. Might as well allow the user to see it.
-}
currentBlock : EventSentry msg -> Maybe Int
currentBlock (EventSentry { blockNumber }) =
    blockNumber



-- Internal


{-| -}
type alias RequestState msg =
    { tagger : Log -> msg
    , ref : Ref
    , logFilter : LogFilter
    , watchOnce : Bool
    , logCount : Int
    }


{-| -}
type alias Ref =
    Int


watch_ : Bool -> (Log -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg, Ref )
watch_ onlyOnce onReceive (EventSentry sentry) logFilter =
    let
        requestState =
            { tagger = onReceive
            , ref = sentry.ref
            , logFilter = logFilter
            , watchOnce = onlyOnce
            , logCount = 0
            }

        newSentry =
            { sentry
                | requests = Dict.insert sentry.ref requestState sentry.requests
                , ref = sentry.ref + 1
            }

        return task =
            ( EventSentry { newSentry | watching = Set.insert sentry.ref newSentry.watching }
            , Task.attempt (GetLogs sentry.ref >> sentry.tagger) task
            , sentry.ref
            )
    in
    case sentry.blockNumber of
        Just blockNum ->
            requestInitialEvents sentry.nodePath logFilter ( blockNum, blockNum )
                |> return

        Nothing ->
            -- If sentry is still waiting for blocknumber, mark request as pending.
            ( EventSentry { newSentry | pending = Set.insert sentry.ref newSentry.pending }
            , Cmd.none
            , sentry.ref
            )



-- Update


{-| -}
type Msg
    = BlockNumber (Result Http.Error Int)
    | GetLogs Ref (Result Http.Error (List Log))


{-| -}
update : Msg -> EventSentry msg -> ( EventSentry msg, Cmd msg )
update msg ((EventSentry sentry) as sentry_) =
    case msg of
        BlockNumber (Ok newBlockNum) ->
            let
                requestHelper blockRange set toTask =
                    Set.toList set
                        |> List.map (\ref -> Dict.get ref sentry.requests)
                        |> Maybe.Extra.values
                        |> List.map
                            (\requestState ->
                                toTask sentry.nodePath requestState.logFilter blockRange
                                    |> Task.attempt (GetLogs requestState.ref >> sentry.tagger)
                            )
                        |> Cmd.batch
            in
            case sentry.blockNumber of
                Just oldBlockNum ->
                    if newBlockNum - oldBlockNum == 0 then
                        ( sentry_
                        , pollBlockNumber sentry.nodePath sentry.tagger
                        )

                    else
                        ( EventSentry { sentry | blockNumber = Just newBlockNum }
                        , Cmd.batch
                            [ pollBlockNumber sentry.nodePath sentry.tagger
                            , requestHelper ( oldBlockNum + 1, newBlockNum ) sentry.watching requestWatchedEvents
                            ]
                        )

                Nothing ->
                    ( EventSentry
                        { sentry
                            | blockNumber = Just newBlockNum
                            , pending = Set.empty
                            , watching = Set.union sentry.watching sentry.pending
                        }
                    , Cmd.batch
                        [ pollBlockNumber sentry.nodePath sentry.tagger
                        , requestHelper ( newBlockNum, newBlockNum ) sentry.pending requestInitialEvents
                        , requestHelper ( newBlockNum, newBlockNum ) sentry.watching requestWatchedEvents
                        ]
                    )

        BlockNumber (Err err) ->
            ( EventSentry { sentry | errors = err :: sentry.errors }
            , pollBlockNumber sentry.nodePath sentry.tagger
            )

        GetLogs ref (Ok logs) ->
            handleLogs sentry_ ref logs

        GetLogs _ (Err err) ->
            ( EventSentry { sentry | errors = err :: sentry.errors }
            , Cmd.none
            )



-- BlockNumber Helpers


pollBlockNumber : HttpProvider -> (Msg -> msg) -> Cmd msg
pollBlockNumber ethNode tagger =
    Process.sleep 2000
        |> Task.andThen (\_ -> Eth.getBlockNumber ethNode)
        |> Task.attempt (BlockNumber >> tagger)


{-| Request logs found within the latest block range.

Defined as a "latest block range" instead of "latest block",
since the possibility of multiple blocks being mined between Eth.getBlockNumber requests is a possibility.

-}
requestWatchedEvents : HttpProvider -> LogFilter -> ( Int, Int ) -> Task Http.Error (List Log)
requestWatchedEvents nodePath logFilter ( fromBlock, toBlock ) =
    Eth.getLogs nodePath
        { logFilter | fromBlock = BlockNum fromBlock, toBlock = BlockNum toBlock }


{-| Request logs within the LogFilter's initially defined range,
and combine it with any logs found in the latest block range.
-}
requestInitialEvents : HttpProvider -> LogFilter -> ( Int, Int ) -> Task Http.Error (List Log)
requestInitialEvents nodePath logFilter ( fromBlock, toBlock ) =
    case logFilter.toBlock of
        BlockNum _ ->
            -- Grab logs in the intitially defined block range, then grab the latest blocks events.
            Eth.getLogs nodePath logFilter
                |> Task.andThen
                    (\logs ->
                        Eth.getLogs nodePath
                            { logFilter | fromBlock = BlockNum fromBlock, toBlock = BlockNum toBlock }
                            |> Task.map ((++) logs)
                    )

        _ ->
            -- Otherwise, just grab the full block range, where we'll include the latest.
            Eth.getLogs nodePath logFilter



-- GetLog Helpers


handleLogs : EventSentry msg -> Ref -> List Log -> ( EventSentry msg, Cmd msg )
handleLogs (EventSentry sentry) ref logs =
    case Dict.get ref sentry.requests of
        Nothing ->
            ( EventSentry sentry, Cmd.none )

        Just requestState ->
            case ( requestState.watchOnce, List.head logs ) of
                ( _, Nothing ) ->
                    ( EventSentry { sentry | requests = updateRequests ref logs sentry.requests }
                    , Cmd.none
                    )

                ( True, Just log ) ->
                    ( EventSentry
                        { sentry
                            | watching = Set.remove ref sentry.watching
                            , requests = updateRequests ref logs sentry.requests
                        }
                    , Task.perform requestState.tagger (Task.succeed log)
                    )

                ( False, _ ) ->
                    ( EventSentry { sentry | requests = updateRequests ref logs sentry.requests }
                    , List.map (\log -> Task.perform requestState.tagger (Task.succeed log)) logs
                        |> Cmd.batch
                    )


{-| Keeps track of log count for each request.
-}
updateRequests : Ref -> List Log -> Dict Ref (RequestState msg) -> Dict Ref (RequestState msg)
updateRequests ref logs requests =
    Dict.update ref
        (Maybe.map
            (\requestState -> { requestState | logCount = List.length logs + requestState.logCount })
        )
        requests
