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
    | Logo
    | Drawer
    | TextField
    | TestTitle
    | TestRow
    | TestName
    | TestResponse
    | TestPassed
    | VerticalBar


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
            , style Logo [ opacity 0.5 ]
            , style Drawer [ Border.dotted, Border.right 0.5 ]
            , style TextField [ Border.dotted, Border.all 0.5 ]
            , style TestTitle [ Border.bottom 0.5, Font.size 20, Font.bold, Font.lineHeight 1.5 ]
            , style TestRow [ Border.bottom 1, Border.right 1, helvetica, Font.size 12, Font.lineHeight 1.2 ]
            , style TestName [ Font.size 16, Font.lineHeight 1.5 ]
            , style TestResponse [ Font.size 16, Font.lineHeight 1.5 ]
            , style TestPassed [ variation Pass [ Color.text Color.green ], variation Fail [ Color.text Color.red ] ]
            , style VerticalBar [ Border.right 1, Border.dotted ]
            ]


type EthNetwork
    = MainNet
    | Ropsten
    | DevNet
    | UnknownNetwork


type alias Test =
    { name : String
    , response : String
    , passed : Bool
    }


type alias Config =
    { account : Address
    , secondaryAccount : Address
    , contract : Address
    , blockNumber : BlockId
    , blockHash : BlockId
    , txId : TxId
    , txParams : TxParams
    , filterParams : FilterParams
    , hexData : Hex
    }


defaultAccount : Account
defaultAccount =
    { privateKey = PrivateKey ("0x7c78d7be18a10ebc4509119e746bb6c69deb5a071b64032799c670037e1541a5")
    , address = Address ("0x7900681181e87B926A279769538f5325088eAdc1")
    }


defaultTxParams : TxParams
defaultTxParams =
    { to = Just (Address "0x6655bb0986fbdfa897312da56e2634f2aced3adc")
    , value = Just (BigInt.fromInt 42424242)
    , gas = 21000
    , data = Nothing
    , gasPrice = Nothing
    , nonce = Just 1
    , chainId = Nothing
    }


mainnetConfig : Config
mainnetConfig =
    { account = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , secondaryAccount = (Address "0x6655bb0986fbdfa897312da56e2634f2aced3adc")
    , contract = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , blockNumber = BlockNum 4182808
    , blockHash = BlockHash "0x000997b870b069a5b1857de507103521860590ca747cf16e46ee38ac456d204e"
    , txId = TxId "0x0bb84e278f50d334022a2c239c90f3c186867b0888e989189ac3c19b27c70372"
    , txParams = defaultTxParams
    , filterParams =
        { address = Just [ (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7") ]
        , fromBlock = Just (BlockNum 320)
        , toBlock = Just (BlockNum 520)
        , topics = Just []
        }
    , hexData = (Hex "0x121212")
    }


ropstenConfig : Config
ropstenConfig =
    { account = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , secondaryAccount = (Address "0x6655bb0986fbdfa897312da56e2634f2aced3adc")
    , contract = (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7")
    , blockNumber = BlockNum 1530779
    , blockHash = BlockHash "0x1562e2c2506d2cfad8a95ef78fd48b507c3ffa62c44a3fc619facc4af191b3de"
    , txId = TxId "0x444b76b68af09969f46eabbbe60eef38f4b0674c4a7cb2e32c7764096997b916"
    , txParams = defaultTxParams
    , filterParams =
        { address = Just [ (Address "0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7") ]
        , fromBlock = Just (BlockNum 320)
        , toBlock = Just (BlockNum 520)
        , topics = Just []
        }
    , hexData = (Hex "0x121212")
    }


devNetConfig : Config
devNetConfig =
    -- { account = (Address "0x7900681181e87b926a279769538f5325088eadc1")
    { account = (Address "0x0212010e3F64a56FD6d7E33Db01279055B553BED")
    , secondaryAccount = (Address "0x6655bb0986fbdfa897312da56e2634f2aced3adc")
    , contract = (Address "0x4bf52d0989ef11d2a5c99d7f7e442fc208813121")
    , blockNumber = BlockNum 320
    , blockHash = BlockHash "0x231a0c9b49d53f0df6f2d5ce2f9d4cbc73efa0d250e64a395869b484b45687bc"
    , txId = TxId "0xbd40b560ac9999751ff6d5125a399a74f0ed192b1dc4273911078b3696fe2503"
    , txParams = defaultTxParams
    , filterParams =
        { address = Just [ (Address "0x853726f791d6fbff51f225587d7fff05ab5930a8") ]
        , fromBlock = Just (BlockNum 320)
        , toBlock = Just (BlockNum 520)
        , topics = Just []
        }
    , hexData = (Hex "0x121212")
    }


getNetwork : Int -> EthNetwork
getNetwork id =
    case id of
        1 ->
            MainNet

        2 ->
            Ropsten

        23 ->
            DevNet

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


zip : List a -> List b -> List ( a, b )
zip =
    List.map2 (,)
