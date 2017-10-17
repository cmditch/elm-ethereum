module Web3.Eth.Accounts
    exposing
        ( create
        , createWithEntropy
        , signTransaction
        , hashMessage
        , sign
        , recoverTx
        , recoverMsg
        , encrypt
        , decrypt
        )

import Task exposing (Task)
import Json.Encode as Encode
import Web3
import Web3.Internal as Internal exposing (CallType(..))
import Web3.Decoders exposing (..)
import Web3.Encoders exposing (encodeKeystore, encodeTxParams)
import Web3.Types exposing (..)


create : Task Error Account
create =
    Internal.toTask
        { method = "eth.accounts.create"
        , params = Encode.list []
        , expect = expectJson accountDecoder
        , callType = Sync
        , applyScope = Just "web3.eth.accounts"
        }


createWithEntropy : String -> Task Error Account
createWithEntropy entropy =
    Internal.toTask
        { method = "eth.accounts.create"
        , params = Encode.list [ Encode.string entropy ]
        , expect = expectJson accountDecoder
        , callType = Sync
        , applyScope = Just "web3.eth.accounts"
        }


signTransaction : Account -> TxParams -> Task Error SignedTx
signTransaction { address, privateKey } txParams =
    Internal.toTask
        { method = "eth.accounts.signTransaction"
        , params =
            Encode.list
                [ encodeTxParams (Just address) txParams
                , Encode.string (privateKeyToString privateKey)
                ]
        , expect = expectJson signedTxDecoder
        , callType = Async
        , applyScope = Just "web3.eth.accounts"
        }


hashMessage : String -> Task Error Sha3
hashMessage message =
    Internal.toTask
        { method = "eth.accounts.hashMessage"
        , params = Encode.list [ Encode.string message ]
        , expect = expectJson sha3Decoder
        , callType = Sync
        , applyScope = Just "web3.eth.accounts"
        }


sign : Account -> String -> Task Error SignedMsg
sign { privateKey } message =
    Internal.toTask
        { method = "eth.accounts.sign"
        , params =
            Encode.list
                [ Encode.string message
                , Encode.string (privateKeyToString privateKey)
                ]
        , expect = expectJson signedMsgDecoder
        , callType = Sync
        , applyScope = Just "web3.eth.accounts"
        }


recoverTx : SignedTx -> Task Error Address
recoverTx { messageHash, v, r, s } =
    Internal.toTask
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
        , applyScope = Just "web3.eth.accounts"
        }


recoverMsg : SignedMsg -> Task Error Address
recoverMsg { messageHash, v, r, s } =
    Internal.toTask
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
        , applyScope = Just "web3.eth.accounts"
        }


encrypt : Account -> String -> Task Error Keystore
encrypt { privateKey } password =
    Internal.toTask
        { method = "eth.accounts.encrypt"
        , params =
            Encode.list
                [ Encode.string (privateKeyToString privateKey)
                , Encode.string password
                ]
        , expect = expectJson keystoreDecoder
        , callType = Sync
        , applyScope = Just "web3.eth.accounts"
        }
        |> Web3.delayExecution


decrypt : Keystore -> String -> Task Error Account
decrypt keystore password =
    Internal.toTask
        { method = "eth.accounts.decrypt"
        , params =
            Encode.list
                [ encodeKeystore keystore
                , Encode.string password
                ]
        , expect = expectJson accountDecoder
        , callType = Sync
        , applyScope = Just "web3.eth.accounts"
        }
        |> Web3.delayExecution
