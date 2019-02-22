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
import Set exposing (Set)
import Task


{-|

    nodePath : HTTP Address of Ethereum Node
    tagger : Wrap an Sentry.Event.Msg in your applications Msg
    requests : Dictionary to keep track of user's event requests
    ref : RPC ID Reference
    blockNumber : The last known block number - `Nothing` if response to first block number request is yet to come.
    deadLetters : If current block number is `Nothing`, event requests will be filed away for another attempt.

-}
type EventSentry msg
    = EventSentry
        { nodePath : HttpProvider
        , tagger : Msg -> msg
        , requests : Dict Int (RequestState msg)
        , ref : Int
        , blockNumber : Maybe Int
        , deadLetters : Set Int
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
        , deadLetters = Set.empty
        }
    , Task.attempt (BlockNumber >> tagger) (Eth.getBlockNumber nodePath)
    )


type alias RequestState msg =
    { tagger : Value -> msg
    , ref : Int
    , logFilter : LogFilter
    , watchOnce : Bool
    , logCount : Int
    }


{-| -}
watchOnce : (Value -> msg) -> EventSentry msg -> LogFilter -> ( EventSentry msg, Cmd msg )
watchOnce onReceive (EventSentry sentry) logFilter =
    let
        filterState =
            { tagger = onReceive
            , ref = sentry.ref
            , logFilter = logFilter
            , watchOnce = True
            , logCount = 0
            }

        newEventSentry =
            { sentry
                | requests = Dict.insert sentry.ref filterState sentry.requests
                , ref = sentry.ref + 1
            }
    in
    case sentry.blockNumber of
        Nothing ->
            ( EventSentry { newEventSentry | deadLetters = Set.insert sentry.ref sentry.deadLetters }
            , Cmd.none
            )

        Just blockNumber ->
            ( EventSentry newEventSentry
            , Cmd.none
            )


type Msg
    = NoOp
    | BlockNumber (Result Http.Error Int)


update : Msg -> EventSentry msg -> ( EventSentry msg, Cmd msg )
update msg ((EventSentry sentry) as sentry_) =
    case msg of
        NoOp ->
            ( sentry_, Cmd.none )

        BlockNumber (Ok blockNumber) ->
            ( sentry_, Cmd.none )

        BlockNumber (Err blockNumber) ->
            ( sentry_, Cmd.none )
