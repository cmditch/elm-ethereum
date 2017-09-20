module Config exposing (..)

import Web3
import Web3.Types exposing (..)
import Task exposing (Task)
import Style exposing (..)
import Color
import Style.Color as Color
import Style.Border as Border


-- Styling


type Styles
    = None
    | Drawer
    | Table


stylesheet : StyleSheet Styles variation
stylesheet =
    Style.styleSheet
        [ style None []
        , style Drawer [ Border.dotted, Border.right 0.5 ]
        , style Table [ Color.background Color.red ]
        ]


type EthNetwork
    = MainNet
    | Ropsten
    | DevNet
    | DevNet2
    | UnknownNetwork


type alias Test =
    { name : String
    , result : String
    , passed : Bool
    }


type alias Config =
    { account : Address
    , contract : Address
    , blockNumber : BlockId
    , blockHash : BlockId
    , txId : TxId
    }


mainnetConfig : Config
mainnetConfig =
    { account = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , contract = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , blockNumber = BlockNum 4182808
    , blockHash = BlockHash "0x000997b870b069a5b1857de507103521860590ca747cf16e46ee38ac456d204e"
    , txId = TxId "0x0bb84e278f50d334022a2c239c90f3c186867b0888e989189ac3c19b27c70372"
    }


ropstenConfig : Config
ropstenConfig =
    { account = (Address "0x10A19C4bD26C8E8203628384083b7ee6819e36B6")
    , contract = (Address "0xdfbE7B4439682E2Ad6F33323b36D89aBF8f295F9")
    , blockNumber = BlockNum 1530779
    , blockHash = BlockHash "0x1562e2c2506d2cfad8a95ef78fd48b507c3ffa62c44a3fc619facc4af191b3de"
    , txId = TxId "0x444b76b68af09969f46eabbbe60eef38f4b0674c4a7cb2e32c7764096997b916"
    }


devNetConfig : Config
devNetConfig =
    { account = (Address "0x853726f791d6fbff51f225587d7fff05ab5930a8")
    , contract = (Address "0x853726f791d6fbff51f225587d7fff05ab5930a8")
    , blockNumber = BlockNum 320
    , blockHash = BlockHash "0x231a0c9b49d53f0df6f2d5ce2f9d4cbc73efa0d250e64a395869b484b45687bc"
    , txId = TxId "0x9ce0dc95c47dd98e0de43143e21028de0a73e05cde86b363228a2164d8645bde"
    }


devNet2Config : Config
devNet2Config =
    { account = (Address "0xd8b0990c007ba1ad97b37c001d1f87044312162e")
    , contract = (Address "0xd8b0990c007ba1ad97b37c001d1f87044312162e")
    , blockNumber = BlockNum 320
    , blockHash = BlockHash "0xc9ec58770c8c49682d388054e9fa9bc6c51848db1393abb59157e7d629861282"
    , txId = TxId "0x56026ef59e927fd95f781865695b28ff260f70bfb79c8392080f5678b33cf100"
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


(?=) : Maybe a -> a -> a
(?=) a b =
    Maybe.withDefault b a
