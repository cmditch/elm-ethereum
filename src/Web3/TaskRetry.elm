module TaskRetry exposing (Retry, retry)

import Json.Decode exposing (Decoder)
import Http
import Task
import Process
import Time


type alias Retry =
    { url : String
    , on : List Int
    , attempts : Int
    , sleep : Float
    }


hasCode : List Int -> Int -> Bool
hasCode codeList code =
    List.member code codeList


retry : Retry -> Decoder a -> Task.Task Http.Error a
retry { url, on, attempts, sleep } decoder =
    let
        remaining =
            attempts - 1
    in
        Http.get url decoder
            |> Http.toTask
            |> Task.onError
                (\x ->
                    case x of
                        Http.BadStatus res ->
                            if (hasCode on res.status.code) && (remaining > 0) then
                                Process.sleep (sleep * Time.millisecond)
                                    |> Task.andThen (\_ -> retry (Retry url on remaining sleep) decoder)
                            else
                                Task.fail x

                        _ ->
                            Task.fail x
                )
