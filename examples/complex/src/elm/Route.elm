module Route exposing (Route(..), fromLocation, link, modifyUrl)

-- Library

import BigInt exposing (BigInt)
import Element as El exposing (Attribute, Element)
import Navigation exposing (Location)
import UrlParser as Url exposing ((</>))


type Route
    = Home
    | Login
    | Widget BigInt


route : Url.Parser (Route -> a) a
route =
    Url.oneOf
        [ Url.map Home Url.top
        , Url.map Login (Url.s "login")
        , Url.map Widget (Url.s "widget" </> bigIntParser)
        ]


routeToString : Route -> String
routeToString route =
    let
        pieces =
            case route of
                Home ->
                    []

                Login ->
                    [ "login" ]

                Widget id ->
                    [ "widget", BigInt.toString id ]
    in
        "#/" ++ String.join "/" pieces



-- PUBLIC HELPERS --


link : Route -> Element style variation msg -> Element style variation msg
link route =
    El.link (routeToString route)


modifyUrl : Route -> Cmd msg
modifyUrl =
    routeToString >> Navigation.modifyUrl


fromLocation : Location -> Maybe Route
fromLocation location =
    if String.isEmpty location.hash then
        Just Home
    else
        Url.parseHash route location



-- PARSERS


bigIntParser : Url.Parser (BigInt -> b) b
bigIntParser =
    Url.custom "BIGINT" (BigInt.fromString >> Result.fromMaybe "BigInt.toString error")
