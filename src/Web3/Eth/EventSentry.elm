module Web3.Eth.EventSentry
    exposing
        ( EventSentry
        , Msg
        , FilterKey
        , init
        , update
        , changeNode
        , listen
        , watch
        , watchOnce
        , unWatch
        , withDebug
        )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Value, Decoder)
import Json.Encode as Encode
import Web3.Utils exposing (keccak256, addressToString)
import Web3.Eth.Types exposing (..)
import Web3.Eth.Encode as Encode
import Web3.JsonRPC as RPC
import WebSocket as WS


-- TYPES


{-| (Contract Address, Event Topic

Need to come up with a better Key scheme to avoid collisions
Maybe by hashing the Filter params

-}
type alias FilterKey =
    ( String, String )


type NodeResponse
    = Subscribed OpenedMsg
    | Event EventMsg
    | Unsubscribed ClosedMsg


type alias OpenedMsg =
    { id : Int, filterId : FilterId }


type alias EventMsg =
    { method : String
    , params : { filterId : FilterId, result : Value }
    }


type alias FilterId =
    String


type FilterStatus
    = Opening
    | Opened


type alias FilterState msg =
    { tagger : Value -> msg
    , status : FilterStatus
    , ref : Int
    , filterId : Maybe FilterId
    , once : Bool
    }



-- MODEL


type alias EventSentry msg =
    { nodePath : String
    , filters : Dict FilterKey (FilterState msg)
    , refToFKey : Dict Int FilterKey
    , fIdToFKey : Dict FilterId FilterKey
    , debug : Bool
    , ref : Int
    }


init : String -> EventSentry msg
init nodePath =
    { nodePath = nodePath
    , filters = Dict.empty
    , refToFKey = Dict.empty
    , fIdToFKey = Dict.empty
    , debug = False
    , ref = 1
    }


changeNode : String -> EventSentry msg -> EventSentry msg
changeNode newNodePath eventSentry =
    { eventSentry | nodePath = newNodePath }



--- UPDATE


type Msg msg
    = NoOp
    | SubscriptionOpened OpenedMsg
    | SubscriptionClosed FilterKey
    | ExternalMsg msg


update : Msg msg -> EventSentry msg -> ( EventSentry msg, Cmd (Msg msg) )
update msg sentry =
    case msg of
        SubscriptionOpened openedMsg ->
            case getFilterByRef openedMsg.id sentry of
                Just ( filterKey, filterState ) ->
                    { sentry
                        | filters =
                            Dict.update filterKey
                                (Maybe.map (setFilterStateOpened openedMsg.filterId))
                                sentry.filters
                        , fIdToFKey =
                            Dict.insert openedMsg.filterId
                                filterKey
                                sentry.fIdToFKey
                    }
                        ! []

                Nothing ->
                    sentry ! []

        SubscriptionClosed filterKey ->
            unWatch filterKey sentry

        _ ->
            sentry ! []


getFilterByRef : Int -> EventSentry msg -> Maybe ( FilterKey, FilterState msg )
getFilterByRef ref sentry =
    Dict.get ref sentry.refToFKey
        |> Maybe.andThen
            (\key ->
                Dict.get key sentry.filters
                    |> Maybe.map (\f -> ( key, f ))
            )


setFilterStateOpened : FilterId -> FilterState msg -> FilterState msg
setFilterStateOpened filterId filterState =
    { filterState | status = Opened, filterId = Just filterId }



-- API


{-| -}
watch : LogFilter -> (Value -> msg) -> EventSentry msg -> ( EventSentry msg, Cmd msg )
watch =
    watch_ False


watchOnce : LogFilter -> (Value -> msg) -> EventSentry msg -> ( EventSentry msg, Cmd msg )
watchOnce =
    watch_ True


watch_ : Bool -> LogFilter -> (Value -> msg) -> EventSentry msg -> ( EventSentry msg, Cmd msg )
watch_ isOnce logFilter onReceive sentry =
    let
        filterKey =
            logFilterKey logFilter
    in
        case Dict.get filterKey sentry.filters of
            Nothing ->
                { sentry
                    | filters = Dict.insert filterKey (makeFilter isOnce onReceive sentry.ref) sentry.filters
                    , refToFKey = Dict.insert sentry.ref filterKey sentry.refToFKey
                    , ref = sentry.ref + 1
                }
                    ! [ WS.send sentry.nodePath <|
                            Encode.encode 0
                                (RPC.encode sentry.ref
                                    "eth_subscribe"
                                    [ Encode.string "logs", Encode.logFilter logFilter ]
                                )
                      ]

            _ ->
                ( sentry, Cmd.none )


{-| -}
unWatch : FilterKey -> EventSentry msg -> ( EventSentry msg, Cmd (Msg msg) )
unWatch filterKey sentry =
    case Dict.get filterKey sentry.filters of
        Nothing ->
            ( sentry, Cmd.none )

        Just filterState ->
            case filterState.filterId of
                Just filterId ->
                    { sentry
                        | filters = Dict.remove filterKey sentry.filters
                        , refToFKey = Dict.remove sentry.ref sentry.refToFKey
                        , fIdToFKey = Dict.remove filterId sentry.fIdToFKey
                    }
                        ! [ WS.send sentry.nodePath (closeFilterRpc sentry.ref filterId) ]

                Nothing ->
                    ( sentry, Cmd.none )


{-| -}
listen : EventSentry msg -> (Msg msg -> msg) -> Sub msg
listen sentry fn =
    (Sub.batch >> Sub.map (mapAll fn))
        [ internalMsgs sentry
        , externalMsgs sentry
        ]


{-| -}
withDebug : EventSentry msg -> EventSentry msg
withDebug sentry =
    { sentry | debug = True }



-- INTERNAL


externalMsgs : EventSentry msg -> Sub (Msg msg)
externalMsgs sentry =
    Sub.map (mapExternalMsgs sentry) (ethNodeMessages sentry)


mapExternalMsgs : EventSentry msg -> Maybe NodeResponse -> Msg msg
mapExternalMsgs sentry maybeResponse =
    case maybeResponse of
        Just (Event eventMsg) ->
            case getFilterById eventMsg.params.filterId sentry of
                Just ( _, filterState ) ->
                    ExternalMsg (filterState.tagger eventMsg.params.result)

                Nothing ->
                    let
                        a =
                            Debug.log "This shouldn't happen: " eventMsg
                    in
                        NoOp

        _ ->
            NoOp


getFilterById : FilterId -> EventSentry msg -> Maybe ( FilterKey, FilterState msg )
getFilterById fId sentry =
    Dict.get fId sentry.fIdToFKey
        |> Maybe.andThen
            (\key ->
                Dict.get key sentry.filters
                    |> Maybe.map (\f -> ( key, f ))
            )


internalMsgs : EventSentry msg -> Sub (Msg msg)
internalMsgs sentry =
    Sub.map (mapInternalMsgs sentry) (ethNodeMessages sentry)


mapInternalMsgs : EventSentry msg -> Maybe NodeResponse -> Msg msg
mapInternalMsgs sentry maybeResponse =
    case maybeResponse of
        Just mess ->
            let
                message =
                    if sentry.debug then
                        Debug.log "Incoming message: " mess
                    else
                        mess
            in
                case message of
                    Subscribed openedMsg ->
                        SubscriptionOpened openedMsg

                    Event eventMsg ->
                        closeIfOnce eventMsg.params.filterId sentry

                    _ ->
                        NoOp

        Nothing ->
            NoOp


closeIfOnce : FilterId -> EventSentry msg -> Msg msg
closeIfOnce id sentry =
    case getFilterById id sentry |> Maybe.map (Tuple.mapSecond .once) of
        Just ( filterKey, True ) ->
            SubscriptionClosed filterKey

        _ ->
            NoOp


ethNodeMessages : EventSentry msg -> Sub (Maybe NodeResponse)
ethNodeMessages sentry =
    WS.listen sentry.nodePath decodeMessage


mapAll : (Msg msg -> msg) -> Msg msg -> msg
mapAll fn internalMsg =
    case internalMsg of
        ExternalMsg msg ->
            msg

        _ ->
            fn internalMsg


makeFilter : Bool -> (Value -> msg) -> Int -> FilterState msg
makeFilter isOnce onReceive ref =
    { tagger = onReceive
    , status = Opening
    , ref = ref
    , filterId = Nothing
    , once = isOnce
    }


logFilterKey : LogFilter -> ( String, String )
logFilterKey { address, topics } =
    let
        eventTopic =
            List.head topics
                |> Maybe.andThen identity
                |> Maybe.withDefault ""
    in
        ( addressToString address, eventTopic )


closeFilterRpc : Int -> String -> String
closeFilterRpc rpcId filterId =
    RPC.encode rpcId "eth_unsubscribe" [ Encode.string filterId ]
        |> Encode.encode 0



-- Decoders


decodeMessage : String -> Maybe NodeResponse
decodeMessage =
    Decode.decodeString nodeResponseDecoder >> Result.toMaybe


nodeResponseDecoder : Decoder NodeResponse
nodeResponseDecoder =
    Decode.oneOf
        [ openedMsgDecoder
        , eventDecoder
        , closedMsgDecoder
        ]


openedMsgDecoder : Decoder NodeResponse
openedMsgDecoder =
    Decode.map Subscribed <|
        Decode.map2 OpenedMsg
            (Decode.field "id" Decode.int)
            (Decode.field "result" Decode.string)


eventDecoder : Decoder NodeResponse
eventDecoder =
    let
        eventParamsDecoder =
            Decode.map2 (\s r -> { filterId = s, result = r })
                (Decode.field "subscription" Decode.string)
                (Decode.field "result" Decode.value)
    in
        Decode.map Event <|
            Decode.map2 EventMsg
                (Decode.field "method" Decode.string)
                (Decode.field "params" eventParamsDecoder)



-- Not using this response yet


closedMsgDecoder : Decoder NodeResponse
closedMsgDecoder =
    Decode.map Unsubscribed <|
        Decode.map2 ClosedMsg
            (Decode.field "id" Decode.int)
            (Decode.field "result" Decode.bool)


type alias ClosedMsg =
    { id : Int, result : Bool }
