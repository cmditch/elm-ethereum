module Eth.Sentry.Event exposing (EventSentry, Msg, Ref, init, stopWatching, update, watch, watchOnce)

{-| Event Sentry - HTTP Style - Polling ftw

@docs EventSentry, Msg, Ref, init, stopWatching, update, watch, watchOnce

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
        , errors = []
        }
    , Task.attempt (BlockNumber >> tagger) (Eth.getBlockNumber nodePath)
    )


{-|

    Returns the first log found.

    If a block range is defined in the LogFilter,
    then returns the first log found within a given block range.

-}
watchOnce : (Log -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg )
watchOnce onReceive eventSentry logFilter =
    watch_ True onReceive eventSentry logFilter
        |> (\( eventSentry_, cmd, _ ) -> ( eventSentry_, cmd ))


{-|

    Continuously polls for logs in newly mined blocks.

    If the range within the LogFilter includes past blocks,
    then all the events within the given range are returned.

    Polling continues until `stopWatching` is called,
    using the `Ref` returned from this function.

-}
watch : (Log -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg, Ref )
watch =
    watch_ False


{-| -}
stopWatching : Ref -> EventSentry msg -> EventSentry msg
stopWatching ref (EventSentry sentry) =
    EventSentry { sentry | watching = Set.remove ref sentry.watching }



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
            EventSentry
                { sentry
                    | requests = Dict.insert sentry.ref requestState sentry.requests
                    , ref = sentry.ref + 1
                }

        return task =
            Task.attempt (GetLogs sentry.ref >> sentry.tagger) task
                |> (\cmd -> ( newSentry, cmd, sentry.ref ))
    in
    case requestState.logFilter.toBlock of
        BlockNum _ ->
            -- Grab logs in the intitially defined block range, then grab the latest blocks events.
            Eth.getLogs sentry.nodePath logFilter
                |> Task.andThen
                    (\logs ->
                        Eth.getLogs sentry.nodePath { logFilter | fromBlock = LatestBlock, toBlock = LatestBlock }
                            |> Task.map ((::) logs)
                    )
                |> return

        _ ->
            -- Otherwise, just grab the full block range, which will include the latest.
            Eth.getLogs sentry.nodePath logFilter
                |> return



--
--watchHelp : RequestState msg -> EventSentry msg -> ( EventSentry msg, Cmd msg, Ref )
--watchHelp requestState (EventSentry sentry) =
--
--
--
-- Update


{-| -}
type Msg
    = BlockNumber (Result Http.Error Int)
    | GetLogs Ref (Result Http.Error (List Log))


{-| -}
update : Msg -> EventSentry msg -> ( EventSentry msg, Cmd msg )
update msg ((EventSentry sentry) as sentry_) =
    case msg of
        BlockNumber (Ok blockNumber) ->
            case sentry.blockNumber of
                Just storedBlockNumber ->
                    if blockNumber - storedBlockNumber == 0 then
                        ( sentry_
                        , pollBlockNumber sentry.nodePath sentry.tagger
                        )

                    else
                        requestEvents ( storedBlockNumber + 1, blockNumber ) sentry_

                Nothing ->
                    ( sentry_
                    , pollBlockNumber sentry.nodePath sentry.tagger
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



-- Update Helpers


pollBlockNumber : HttpProvider -> (Msg -> msg) -> Cmd msg
pollBlockNumber ethNode tagger =
    Process.sleep 2000
        |> Task.andThen (\_ -> Eth.getBlockNumber ethNode)
        |> Task.attempt (BlockNumber >> tagger)



-- TODO - Fix the whole lastCheckedBlock abstraction


requestEvents : ( Int, Int ) -> EventSentry msg -> ( EventSentry msg, Cmd msg )
requestEvents ( fromBlock, currentBlock ) (EventSentry sentry) =
    let
        getLogs =
            Set.toList sentry.watching
                |> List.map (\ref -> Dict.get ref sentry.requests)
                |> Maybe.Extra.values
                |> List.map
                    (\requestState ->
                        case requestState.lastCheckedBlock of
                            Just lastCheckedBlock ->
                                if lastCheckedBlock < fromBlock then
                                    updateRange ( fromBlock, currentBlock ) requestState.logFilter
                                        |> Eth.getLogs sentry.nodePath
                                        |> Task.attempt (GetLogs requestState.ref >> sentry.tagger)

                                else
                                    Cmd.none

                            Nothing ->
                                Cmd.none
                    )
                |> Cmd.batch

        newRequests =
            Dict.map (\key req -> { req | lastCheckedBlock = Just currentBlock }) sentry.requests
    in
    ( EventSentry { sentry | blockNumber = Just currentBlock, requests = newRequests }
    , Cmd.none
    )


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


{-| Keeps track of log count for each request, and mutates the LogFilter range to watch the latest block.
-}
updateRequests : Ref -> List Log -> Dict Ref (RequestState msg) -> Dict Ref (RequestState msg)
updateRequests ref logs requests =
    Dict.update ref
        (Maybe.map
            (\requestState -> { requestState | logCount = List.length logs + requestState.logCount })
        )
        requests



-- Misc


updateRange : ( Int, Int ) -> LogFilter -> LogFilter
updateRange ( fromBlock, toBlock ) logFilter =
    { logFilter
        | fromBlock = BlockNum fromBlock
        , toBlock = BlockNum toBlock
    }
