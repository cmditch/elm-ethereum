module Web3.Eth.Accounts
    exposing
        ( create
        , createWithEntropy
        )

import Task exposing (Task)
import Json.Encode as Encode
import Web3
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (encodeKeystore, encodeTxParams, encodeCustomTxParams)
import Web3.Types exposing (..)


create : Task Error Account
create =
    Web3.toTask
        { method = "eth.accounts.create"
        , params = Encode.list []
        , expect = expectJson accountDecoder
        , callType = Sync
        , applyScope = Just "web3.eth.accounts"
        }


createWithEntropy : String -> Task Error Account
createWithEntropy entropy =
    Web3.toTask
        { method = "eth.accounts.create"
        , params = Encode.list [ Encode.string entropy ]
        , expect = expectJson accountDecoder
        , callType = Sync
        , applyScope = Just "web3.eth.accounts"
        }


signTransaction : Account -> TxParams -> Task Error SignedTx
signTransaction { privateKey } txParams =
    Web3.toTask
        { method = "eth.accounts.signTransaction"
        , params =
            Encode.list
                [ encodeTxParams txParams
                , Encode.string (privateKeyToString privateKey)
                ]
        , expect = expectJson signedTxDecoder
        , callType = Async
        , applyScope = Nothing
        }


signTransactionAtChain : Int -> Account -> TxParams -> Task Error SignedTx
signTransactionAtChain chainId { privateKey } txParams =
    Web3.toTask
        { method = "eth.accounts.signTransaction"
        , params =
            Encode.list
                [ encodeCustomTxParams [ ( "chainId", Just <| Encode.int chainId ) ] txParams
                , Encode.string (privateKeyToString privateKey)
                ]
        , expect = expectJson signedTxDecoder
        , callType = Sync
        , applyScope = Nothing
        }


hashMessage : String -> Task Error Sha3
hashMessage message =
    Web3.toTask
        { method = "eth.accounts.hashMessage"
        , params = Encode.list [ Encode.string message ]
        , expect = expectJson sha3Decoder
        , callType = Sync
        , applyScope = Nothing
        }


sign : Account -> String -> Task Error SignedTx
sign { privateKey } message =
    Web3.toTask
        { method = "eth.accounts.sign"
        , params =
            Encode.list
                [ Encode.string message
                , Encode.string (privateKeyToString privateKey)
                ]
        , expect = expectJson signedTxDecoder
        , callType = Sync
        , applyScope = Nothing
        }


recover : SignedTx -> Task Error Address
recover { messageHash, v, r, s } =
    Web3.toTask
        { method = "eth.accounts.recover"
        , params =
            Encode.list
                [ Encode.string (sha3ToString messageHash)
                , Encode.string (hexToString v)
                , Encode.string (hexToString r)
                , Encode.string (hexToString s)
                ]
        , expect = expectJson addressDecoder
        , callType = Sync
        , applyScope = Nothing
        }


encrypt : Account -> String -> Task Error Keystore
encrypt { privateKey } password =
    Web3.toTask
        { method = "eth.accounts.encrypt"
        , params =
            Encode.list
                [ Encode.string (privateKeyToString privateKey)
                , Encode.string password
                ]
        , expect = expectJson keystoreDecoder
        , callType = Sync
        , applyScope = Nothing
        }


decrypt : Keystore -> String -> Task Error Account
decrypt keystore password =
    Web3.toTask
        { method = "eth.accounts.decrypt"
        , params =
            Encode.list
                [ encodeKeystore keystore
                , Encode.string password
                ]
        , expect = expectJson accountDecoder
        , callType = Sync
        , applyScope = Nothing
        }
