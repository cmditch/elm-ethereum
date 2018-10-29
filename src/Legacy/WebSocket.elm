module Legacy.WebSocket exposing (listen)

-- Stubbing out websockets to compile for the time being


listen : String -> (String -> msg) -> Sub msg
listen a b =
    Sub.none


send : String -> String -> Cmd msg
send a b =
    Cmd.none
