module Request.UPort exposing (..)

import Base64
import List.Extra as ListExtra
import Json.Decode as Decode exposing (Decoder, decodeString, map, oneOf, string)
import Json.Decode.Pipeline exposing (custom, decode, required, requiredAt)


authEndpoint : String
authEndpoint =
    "ws://uport-Publi-BD0Y18RWXQQQ-1440329705.us-west-2.elb.amazonaws.com"


type Message
    = Request RequestData
    | Success SuccessData
    | Error ErrorData


type alias RequestData =
    { uri : String
    , qr : String
    }


type alias SuccessData =
    { user : User }


type alias ErrorData =
    { error : String }


type alias User =
    { publicKey : String
    , publicEncKey : String
    , name : String
    , email : String
    , avatar : String
    , address : String
    , networkAddress : String
    }


decodeMessage : (Message -> msg) -> String -> msg
decodeMessage tag raw =
    case decodeString messageDecoder raw of
        Err error ->
            tag <| Error { error = error }

        Ok message ->
            tag message


messageDecoder : Decoder Message
messageDecoder =
    oneOf
        [ map Request requestDecoder
        , map Success successDecoder
        , map Error errorDecoder
        ]


requestDecoder : Decoder RequestData
requestDecoder =
    decode RequestData
        |> required "uri" string
        |> required "qr" string


errorDecoder : Decoder ErrorData
errorDecoder =
    decode ErrorData
        |> required "error" string


{-| Turns a JWT into a User.

1.  Receive JWT from uPort a service: {'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXQiOnsiQGN...M0NjQ3fQ.3b9Io8IFmmGjJWljGBGzKR7U2AR209QF_WYp61qpgbc'}
2.  Convert "token" field data from base64 to json string. "{'dat': { 'name': ..., 'email': ...} }"
3.  Decode "dat" field into User type

-}
successDecoder : Decoder SuccessData
successDecoder =
    decode SuccessData
        |> required "token" userJWTDecoder


userJWTDecoder : Decoder User
userJWTDecoder =
    let
        base64ToUser : String -> Result String User
        base64ToUser s =
            String.split "." s
                |> ListExtra.getAt 1
                |> Result.fromMaybe "Error decoding JWT"
                |> Result.andThen Base64.decode
                |> Result.andThen (Decode.decodeString (Decode.field "dat" userDecoder))
    in
        Decode.string
            |> Decode.andThen
                (\str ->
                    case base64ToUser str of
                        Err err ->
                            Decode.fail err

                        Ok suc ->
                            Decode.succeed suc
                )


userDecoder : Decoder User
userDecoder =
    decode User
        |> required "publicKey" string
        |> required "publicEncKey" string
        |> required "name" string
        |> required "email" string
        |> requiredAt [ "avatar", "uri" ] string
        |> required "address" string
        |> required "networkAddress" string
