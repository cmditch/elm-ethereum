module Web3.Types
    exposing
        ( Hex
        , Address
        , IPFSHash
        , TxHash
        , BlockId
        , toAddress
        )

import BigInt exposing (BigInt)
import Json.Decode exposing (Decoder)
import Web3.Internal.Hex as Hex
import Web3.Internal.Types as Internal
import Web3.Internal.Utils as Internal


toAddress : String -> Result String Address
toAddress =
    Internal.toAddress


type alias Address =
    Internal.Address


type alias TxHash =
    Internal.TxHash


type alias Hex =
    Internal.Hex


type alias IPFSHash =
    Internal.IPFSHash


type BlockId
    = BlockNum Int
    | BlockHash Hex
    | Earliest
    | Latest
    | Pending


type alias TxParams a =
    { to : Maybe Address
    , from : Maybe Address
    , gas : Maybe Int
    , gasPrice : Maybe BigInt
    , value : Maybe BigInt
    , data : Maybe Hex
    , nonce : Maybe Int
    , decoder : Decoder a
    }


type alias Send =
    { to : Maybe Address
    , from : Maybe Address
    , gas : Maybe Int
    , gasPrice : Maybe BigInt
    , value : Maybe BigInt
    , data : Maybe Hex
    , nonce : Maybe Int
    }


{-| TODO: NEED TO FINISH
-}
type alias Tx =
    { hash : TxHash
    , nonce : Int
    , gas : Int
    , input : String
    }


type alias TxReceipt =
    { hash : TxHash
    , index : String
    , blockHash : String
    , blockNumber : String
    , gasUsed : String
    , cumulativeGasUsed : String
    , contractAddress : Maybe Address
    , logs : List Log
    }


{-| -}
type alias Log =
    { address : Address
    , data : String
    , topics : List String
    , logIndex : Maybe String
    , transactionIndex : String
    , transactionHash : TxHash
    , blockHash : Maybe String
    , blockNumber : Maybe String
    }


type alias Event a =
    { address : Address
    , data : String
    , topics : List String
    , logIndex : Maybe String
    , transactionIndex : String
    , transactionHash : TxHash
    , blockHash : Maybe String
    , blockNumber : Maybe String
    , returnData : a
    }


{-| NOTE: Different from JSON RPC API, removed some optionality to reduce complexity
-}
type alias LogFilter =
    { fromBlock : BlockId
    , toBlock : BlockId
    , address : Address
    , topics : List (Maybe String)
    }


type NetworkId
    = Mainnet
    | Expanse
    | Ropsten
    | Rinkeby
    | RskMain
    | RskTest
    | Kovan
    | ETCMain
    | ETCTest
    | Private Int



-- type alias TxReceipt =
--     { transactionHash : TxId
--     , transactionIndex : Int
--     , blockHash : String
--     , blockNumber : Int
--     , gasUsed : Int
--     , cumulativeGasUsed : Int
--     , contractAddress : Maybe Address
--     , logs : List Log
--     }
-- {-| -}
-- type alias Log =
--     { address : Address
--     , data : String
--     , topics : List String
--     , logIndex : Maybe Int
--     , transactionIndex : Int
--     , transactionHash : TxId
--     , blockHash : Maybe String
--     , blockNumber : Maybe Int
--     }
