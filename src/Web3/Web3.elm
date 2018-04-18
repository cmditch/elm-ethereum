module Web3 exposing (clientVersion)


clientVersion : HttpProvider -> Task Http.Error String
clientVersion ethNode =
    RPC.buildRequest
        { url = ethNode
        , method = "web3_clientVersion"
        , params = []
        , decoder = Decode.string
        }
