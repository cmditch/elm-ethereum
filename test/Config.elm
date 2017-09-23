module Config exposing (..)

import Web3
import Web3.Types exposing (..)
import Task exposing (Task)
import Style exposing (..)
import Color
import Style.Color as Color
import Style.Border as Border
import Style.Font as Font
import BigInt


-- Styling


type Styles
    = None
    | Drawer
    | TextField
    | TestTitle
    | TestRow
    | TestName
    | TestResponse
    | TestPassed


type Variations
    = Pass
    | Fail


stylesheet : StyleSheet Styles Variations
stylesheet =
    let
        helvetica =
            [ Font.font "Helvetica" ] |> Font.typeface
    in
        Style.styleSheet
            [ style None []
            , style Drawer [ Border.dotted, Border.right 0.5 ]
            , style TextField [ Border.dotted, Border.all 0.5 ]
            , style TestTitle [ Border.bottom 0.5, Font.size 20, Font.bold, Font.lineHeight 1.5 ]
            , style TestRow [ Border.bottom 1, Border.right 1, helvetica, Font.size 12, Font.lineHeight 1.2 ]
            , style TestName []
            , style TestResponse []
            , style TestPassed [ variation Pass [ Color.text Color.green ], variation Fail [ Color.text Color.red ] ]
            ]


type EthNetwork
    = MainNet
    | Ropsten
    | DevNet
    | DevNet2
    | UnknownNetwork


type alias Test =
    { name : String
    , response : String
    , passed : Bool
    }


type alias Config =
    { account : Address
    , contract : Address
    , blockNumber : BlockId
    , blockHash : BlockId
    , txId : TxId
    , txParams : TxParams
    }


defaultTxParams : TxParams
defaultTxParams =
    { from = Just (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , to = Just (Address "0xd8b0990c007ba1ad97b37c001d1f87044312162e")
    , value = Just (BigInt.fromInt 42424242)
    , gas = Just 123132123
    , data = Just (Hex "0x23123123123123123")
    , gasPrice = Just 132123123
    , nonce = Just 2
    }


mainnetConfig : Config
mainnetConfig =
    { account = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , contract = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , blockNumber = BlockNum 4182808
    , blockHash = BlockHash "0x000997b870b069a5b1857de507103521860590ca747cf16e46ee38ac456d204e"
    , txId = TxId "0x0bb84e278f50d334022a2c239c90f3c186867b0888e989189ac3c19b27c70372"
    , txParams = defaultTxParams
    }


ropstenConfig : Config
ropstenConfig =
    { account = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , contract = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , blockNumber = BlockNum 1530779
    , blockHash = BlockHash "0x1562e2c2506d2cfad8a95ef78fd48b507c3ffa62c44a3fc619facc4af191b3de"
    , txId = TxId "0x444b76b68af09969f46eabbbe60eef38f4b0674c4a7cb2e32c7764096997b916"
    , txParams = defaultTxParams
    }


devNetConfig : Config
devNetConfig =
    { account = (Address "0x853726f791d6fbff51f225587d7fff05ab5930a8")
    , contract = (Address "0x853726f791d6fbff51f225587d7fff05ab5930a8")
    , blockNumber = BlockNum 320
    , blockHash = BlockHash "0x231a0c9b49d53f0df6f2d5ce2f9d4cbc73efa0d250e64a395869b484b45687bc"
    , txId = TxId "0x9ce0dc95c47dd98e0de43143e21028de0a73e05cde86b363228a2164d8645bde"
    , txParams = defaultTxParams
    }


devNet2Config : Config
devNet2Config =
    { account = (Address "0xd8b0990c007ba1ad97b37c001d1f87044312162e")
    , contract = (Address "0xd8b0990c007ba1ad97b37c001d1f87044312162e")
    , blockNumber = BlockNum 320
    , blockHash = BlockHash "0xc9ec58770c8c49682d388054e9fa9bc6c51848db1393abb59157e7d629861282"
    , txId = TxId "0x56026ef59e927fd95f781865695b28ff260f70bfb79c8392080f5678b33cf100"
    , txParams = defaultTxParams
    }


getNetwork : Int -> EthNetwork
getNetwork id =
    case id of
        1 ->
            MainNet

        2 ->
            Ropsten

        42513 ->
            DevNet

        42512 ->
            DevNet2

        _ ->
            UnknownNetwork


getConfig : EthNetwork -> Config
getConfig ethNetwork =
    case ethNetwork of
        MainNet ->
            mainnetConfig

        Ropsten ->
            ropstenConfig

        DevNet ->
            devNetConfig

        DevNet2 ->
            devNet2Config

        UnknownNetwork ->
            devNetConfig


retryThrice : Task Error a -> Task Error a
retryThrice =
    Web3.retry { attempts = 3, sleep = 1 }


resultToTask : Result x a -> Task x a
resultToTask result =
    case result of
        Ok val ->
            Task.succeed val

        Err err ->
            Task.fail err


(?=) : Maybe a -> a -> a
(?=) a b =
    Maybe.withDefault b a
