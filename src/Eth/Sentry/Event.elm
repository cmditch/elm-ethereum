module Eth.Sentry.Event exposing (init)

{- -}

import BigInt
import Dict exposing (Dict)
import Eth
import Eth.Defaults as Default
import Eth.RPC as RPC
import Eth.Types exposing (..)
import Eth.Utils as U exposing (addressToString, keccak256)
import Http
import Internal.Decode as Decode
import Internal.Encode as Encode
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Maybe.Extra
import Process
import Set exposing (Set)
import Task exposing (Task)


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
        , requests : Dict Int (RequestState msg)
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
watchOnce onReceive (EventSentry sentry) logFilter =
    let
        requestState =
            { tagger = onReceive
            , ref = sentry.ref
            , logFilter = logFilter
            , watchOnce = True
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
            )

        Just blockNumber ->
            ( EventSentry newEventSentry
            , logFilterAtBlock blockNumber logFilter
                |> Eth.getLogs sentry.nodePath
                |> Task.attempt (GetLogs sentry.ref >> sentry.tagger)
            )



-- Internal


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
                        [ Task.attempt (BlockNumber >> sentry.tagger) (pollBlockNumber sentry.nodePath)
                        , requestEvents blockNumber sentry_
                        ]
                    )

                True ->
                    ( EventSentry { sentry | blockNumber = Just blockNumber }
                    , Task.attempt (BlockNumber >> sentry.tagger) (pollBlockNumber sentry.nodePath)
                    )

        BlockNumber (Err err) ->
            ( EventSentry { sentry | errors = err :: sentry.errors }
            , Task.attempt (BlockNumber >> sentry.tagger) (pollBlockNumber sentry.nodePath)
            )

        GetLogs ref (Ok logs) ->
            handleLogs sentry_ ref logs

        GetLogs _ (Err err) ->
            ( EventSentry { sentry | errors = err :: sentry.errors }
            , Cmd.none
            )


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


logFilterAtBlock : Int -> LogFilter -> LogFilter
logFilterAtBlock blockNumber logFilter =
    { logFilter | fromBlock = BlockNum blockNumber, toBlock = BlockNum blockNumber }


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
                    ( EventSentry sentry
                    , Cmd.none
                    )

                ( False, _ ) ->
                    ( EventSentry sentry
                    , Cmd.none
                    )


pollBlockNumber : HttpProvider -> Task Http.Error Int
pollBlockNumber nodePath =
    Process.sleep 2
        |> Task.andThen (\_ -> Eth.getBlockNumber nodePath)
