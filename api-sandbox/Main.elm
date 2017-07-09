port module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Web3 exposing (..)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = GetBlockNumber
    | Web3Response String


type alias Model =
    { blockNumber : Maybe Int
    , web3 : Web3.Model
    , response : String
    }


init : ( Model, Cmd Msg )
init =
    { blockNumber = Nothing
    , web3 = Web3.init
    , response = "No Blocks yet"
    }
        ! []


view : Model -> Html Msg
view model =
    div []
        [ div [] [ viewBlockNumber model ]
        , button [ onClick GetBlockNumber ] [ text "Get Block" ]
        , div [] [ text model.response ]
        , br [] []
        , div [] [ text "Converting a type to look like a function. Perhaps useful." ]
        , div [] [ text <| web3Func <| deCapitalize <| toString GetBlockNumber ]
        ]


viewBlockNumber : Model -> Html Msg
viewBlockNumber model =
    case model.blockNumber of
        Nothing ->
            text "Press button plz"

        Just n ->
            text (toString n)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetBlockNumber ->
            let
                request =
                    Web3.Request "eth.getBlockNumber" [] 1
            in
                model ! [ web3request request ]

        Web3Response response ->
            { model | response = response } ! []


web3Func : String -> String
web3Func func =
    "web3.eth." ++ func ++ "()"


deCapitalize : String -> String
deCapitalize word =
    (String.slice 1 (String.length word) word)
        |> (++) (String.toLower (String.slice 0 1 word))


port web3request : Web3.Request -> Cmd msg


port web3response : (Web3.Response -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ web3response Web3Response ]
