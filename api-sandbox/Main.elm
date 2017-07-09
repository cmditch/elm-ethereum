module Main exposing (..)

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
    | GetBlockNumberResponse String
    | Web3Response Web3.Response


type alias Model =
    { blockNumber : Maybe String
    , web3 : Web3State Msg
    }


init : ( Model, Cmd Msg )
init =
    { blockNumber = Nothing
    , web3 = Web3.init
    }
        ! []


view : Model -> Html Msg
view model =
    div []
        [ div [] [ viewBlockNumber model ]
        , button [ onClick GetBlockNumber ] [ text "Get Block" ]
        , br [] []
        , div [] [ text "Converting a type to look like a function. Perhaps useful." ]
        , div [] [ text <| web3Func <| deCapitalize <| GetBlockNumber ]
        ]


viewBlockNumber : Model -> Html Msg
viewBlockNumber model =
    model.blockNumber |> Maybe.withDefault "Press button plz"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetBlockNumber ->
            let
                ( web3_, cmd ) =
                    Web3.getBlockNumber model.web3 GetBlockNumberResponse
            in
                ({ model | web3 = web3_ }) ! [ cmd ]

        GetBlockNumberResponse blockNumber ->
            ( { model | blockNumber = Just blockNumber }, Cmd.none )

        Web3Response response ->
            -- TODO
            -- we know this will be a string at the moment, but will likely need
            -- custom decoders for each function (some results are objects)
            { model | response = response } ! []


web3Func : String -> String
web3Func func =
    "web3.eth." ++ func ++ "()"


deCapitalize : String -> String
deCapitalize word =
    (String.slice 1 (String.length word) word)
        |> (++) (String.toLower (String.slice 0 1 word))


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Web3.response Web3Response ]
