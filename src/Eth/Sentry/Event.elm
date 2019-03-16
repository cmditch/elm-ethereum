module Eth.Sentry.Event exposing
    ( EventSentry
    , Msg
    , Ref
    , init
    , stopWatching
    , update
    , watch
    , watchOnce
    )

{- -}

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


{-|

    nodePath : HTTP Address of Ethereum Node
    tagger : Wrap an Sentry.Event.Msg in your applications Msg
    requests : Dictionary to keep track of user's event requests
    ref : RPC ID Reference
    blockNumber : The last known block number - `Nothing` if response to first block number request is yet to come.
    watching : List of events currently being watched for.

-}
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


{-| -}
watchOnce : (Log -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg )
watchOnce onReceive eventSentry logFilter =
    watch_ True onReceive eventSentry logFilter
        |> (\( eventSentry_, cmd, _ ) -> ( eventSentry_, cmd ))


{-| -}
watch : (Log -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg, Ref )
watch =
    watch_ False


{-| -}
stopWatching : Ref -> EventSentry msg -> EventSentry msg
stopWatching ref (EventSentry sentry) =
    EventSentry { sentry | watching = Set.remove ref sentry.watching }



-- Internal


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

        newEventSentry =
            { sentry
                | requests = Dict.insert sentry.ref requestState sentry.requests
                , ref = sentry.ref + 1
            }
    in
    case sentry.blockNumber of
        Nothing ->
            ( EventSentry { newEventSentry | watching = Set.insert sentry.ref sentry.watching }
            , Cmd.none
            , sentry.ref
            )

        Just blockNumber ->
            ( EventSentry newEventSentry
            , logFilterAtBlock blockNumber logFilter
                |> Eth.getLogs sentry.nodePath
                |> Task.attempt (GetLogs sentry.ref >> sentry.tagger)
            , sentry.ref
            )


type alias RequestState msg =
    { tagger : Log -> msg
    , ref : Ref
    , logFilter : LogFilter
    , watchOnce : Bool
    , logCount : Int
    }


type alias Ref =
    Int



-- Update


type Msg
    = BlockNumber (Result Http.Error Int)
    | GetLogs Ref (Result Http.Error (List Log))


update : Msg -> EventSentry msg -> ( EventSentry msg, Cmd msg )
update msg ((EventSentry sentry) as sentry_) =
    case msg of
        BlockNumber (Ok blockNumber) ->
            case Just blockNumber == sentry.blockNumber of
                False ->
                    ( EventSentry { sentry | blockNumber = Just blockNumber }
                    , Cmd.batch
                        [ pollBlockNumber sentry_
                        , requestEvents blockNumber sentry_
                        ]
                    )

                True ->
                    ( sentry_
                    , pollBlockNumber sentry_
                    )

        BlockNumber (Err err) ->
            ( EventSentry { sentry | errors = err :: sentry.errors }
            , pollBlockNumber sentry_
            )

        GetLogs ref (Ok logs) ->
            handleLogs sentry_ ref logs

        GetLogs _ (Err err) ->
            ( EventSentry { sentry | errors = err :: sentry.errors }
            , Cmd.none
            )



-- Update Helpers


pollBlockNumber : EventSentry msg -> Cmd msg
pollBlockNumber (EventSentry sentry) =
    Process.sleep 2000
        |> Task.andThen (\_ -> Eth.getBlockNumber sentry.nodePath)
        |> Task.attempt (BlockNumber >> sentry.tagger)


requestEvents : Int -> EventSentry msg -> Cmd msg
requestEvents blockNumber (EventSentry sentry) =
    Set.toList sentry.watching
        |> List.map (\ref -> Dict.get ref sentry.requests)
        |> Maybe.Extra.values
        |> List.map
            (\requestState ->
                logFilterAtBlock blockNumber requestState.logFilter
                    |> Eth.getLogs sentry.nodePath
                    |> Task.attempt (GetLogs requestState.ref >> sentry.tagger)
            )
        |> Cmd.batch


handleLogs : EventSentry msg -> Ref -> List Log -> ( EventSentry msg, Cmd msg )
handleLogs (EventSentry sentry) ref logs =
    case Dict.get ref sentry.requests of
        Nothing ->
            ( EventSentry sentry, Cmd.none )

        Just requestState ->
            case ( requestState.watchOnce, List.head logs ) of
                ( _, Nothing ) ->
                    ( EventSentry sentry
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


updateRequests : Ref -> List Log -> Dict Ref (RequestState msg) -> Dict Ref (RequestState msg)
updateRequests ref logs requests =
    Dict.update ref
        (Maybe.map (\requestState -> { requestState | logCount = List.length logs + requestState.logCount }))
        requests



-- Misc


logFilterAtBlock : Int -> LogFilter -> LogFilter
logFilterAtBlock blockNumber logFilter =
    { logFilter
        | fromBlock = BlockNum blockNumber
        , toBlock = BlockNum blockNumber
    }
