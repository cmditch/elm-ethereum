module Pages.Accounts exposing (..)

import Element exposing (..)
import Config exposing (..)
import Task exposing (Task)
import Web3.Types exposing (..)
import Element.Attributes exposing (..)
import Web3.Eth.Accounts as Accounts
import Element.Events exposing (..)
import Element.Input as Input exposing (Text)


init : Model
init =
    { newAccount = Nothing
    , entropy = ""
    , signedMsg = Nothing
    , signedTx = Nothing
    , hashedMessage = Nothing
    , recoveredMsgAddress = Nothing
    , recoveredTxAddress = Nothing
    , encryptedAccount = Nothing
    , decryptedKeystore = Nothing
    , error = Nothing
    }


type alias Model =
    { newAccount : Maybe Account
    , entropy : String
    , signedMsg : Maybe SignedMsg
    , signedTx : Maybe SignedTx
    , hashedMessage : Maybe Sha3
    , recoveredMsgAddress : Maybe Address
    , recoveredTxAddress : Maybe Address
    , encryptedAccount : Maybe Keystore
    , decryptedKeystore : Maybe Account
    , error : Maybe Error
    }


initCreateAccount : Cmd Msg
initCreateAccount =
    Task.attempt Create Accounts.create


viewAccountTests : Model -> List (Element Styles Variations Msg)
viewAccountTests model =
    let
        entropyTextfieldConfig =
            { onChange = Entropy
            , value = model.entropy
            , label = Input.placeholder { text = "Define Entropy", label = Input.hiddenLabel "Paste entropy" }
            , options = []
            }

        createAccount =
            row TestRow
                [ spacing 20, paddingXY 20 20 ]
                [ column None [] [ button None [ onClick InitCreate, width (px 230) ] (text "Create Account") ]
                ]

        viewAccount account =
            row TestResponse
                [ verticalCenter ]
                [ column None
                    [ spacing 10 ]
                    [ text <| toString account.address, text <| toString account.privateKey ]
                ]

        viewKeystore keystore =
            let
                viewCrypto crypto =
                    column None
                        [ spacing 3, moveRight 40, paddingXY 0 5 ]
                        [ text <| "Ciphertext: " ++ crypto.ciphertext
                        , text <| "Cipherparams: " ++ toString crypto.cipherparams
                        , text <| "Cipher: " ++ crypto.cipher
                        , text <| "kdf: " ++ crypto.kdf
                        , text <| "mac: " ++ crypto.mac
                        , text <| "kdfparams: "
                        , viewKdfparams crypto.kdfparams
                        ]

                viewKdfparams kdfparams =
                    column None
                        [ spacing 3, moveRight 60, paddingXY 0 5 ]
                        [ text <| "dklen: " ++ toString kdfparams.dklen
                        , text <| "salt: " ++ kdfparams.salt
                        , text <| "n: " ++ toString kdfparams.n
                        , text <| "r: " ++ toString kdfparams.r
                        , text <| "p: " ++ toString kdfparams.p
                        ]
            in
                row TestResponse
                    []
                    [ column None
                        [ spacing 5 ]
                        [ text <| "Version: " ++ (toString keystore.version)
                        , text <| "Id: " ++ keystore.id
                        , text <| "Address: " ++ keystore.address
                        , text <| "Crypto: "
                        , viewCrypto keystore.crypto
                        ]
                    ]

        viewNewAccount account =
            row TestRow
                [ spacing 20, paddingXY 20 13, xScrollbar ]
                [ column None
                    [ verticalCenter, spacing 15 ]
                    [ button Button [ onClick InitCreate ] (text "Create Account")
                    , row None
                        [ spacing 15 ]
                        [ Input.text TextField [] entropyTextfieldConfig
                        , button Button [ onClick InitCreateWithEntropy ] (text "Create w/ Entropy")
                        ]
                    ]
                , viewAccount account
                ]

        viewTestRow name elements =
            row TestRow
                [ spacing 20, paddingXY 20 0 ]
                [ column TestName [ verticalCenter, minWidth (px 180), paddingXY 0 15 ] [ text name ]
                , column VerticalBar [] []
                , row TestResponse [ verticalCenter, paddingXY 0 10, xScrollbar ] [ column None [ spacing 5 ] elements ]
                ]

        signMessage =
            case model.signedMsg of
                Nothing ->
                    row None [] []

                Just { message, messageHash, r, s, v, signature } ->
                    viewTestRow "Signed Msg"
                        [ text ("Message: " ++ (toString message))
                        , text ("MessageHash: " ++ (toString messageHash))
                        , text ("r: " ++ (toString r))
                        , text ("s: " ++ (toString s))
                        , text ("v: " ++ (toString v))
                        , text ("signature: " ++ (toString signature))
                        ]

        signTransaction =
            case model.signedTx of
                Nothing ->
                    row None [] []

                Just { messageHash, r, s, v, rawTransaction } ->
                    viewTestRow "Signed Tx"
                        [ text ("MessageHash: " ++ (toString messageHash))
                        , text ("r: " ++ (toString r))
                        , text ("s: " ++ (toString s))
                        , text ("v: " ++ (toString v))
                        , text ("signature: " ++ (toString rawTransaction))
                        ]

        hashMessage =
            case model.hashedMessage of
                Nothing ->
                    row None [] []

                Just (Sha3 hashedMessage) ->
                    viewTestRow "Hashed Msg"
                        [ text hashedMessage ]

        recoverMsg =
            case model.recoveredMsgAddress of
                Nothing ->
                    row None [] []

                Just (Address address) ->
                    viewTestRow "Recovered Msg Address"
                        [ text address ]

        recoverTx =
            case model.recoveredTxAddress of
                Nothing ->
                    row None [] []

                Just (Address address) ->
                    viewTestRow "Recovered Tx Address"
                        [ text address ]

        encryptedKeystore =
            case model.encryptedAccount of
                Nothing ->
                    row None [] []

                Just keystore ->
                    viewTestRow "Encrypted Keystore"
                        [ viewKeystore keystore ]

        decryptedKeystore =
            case model.decryptedKeystore of
                Nothing ->
                    row None [] []

                Just account ->
                    viewTestRow "Decrypted Keystore"
                        [ viewAccount account ]
    in
        case model.newAccount of
            Nothing ->
                [ createAccount ]

            Just account ->
                [ viewNewAccount account
                , signMessage
                , signTransaction
                , hashMessage
                , recoverMsg
                , recoverTx
                , encryptedKeystore
                , decryptedKeystore
                ]


titleRow : Model -> List (Element Styles Variations Msg)
titleRow model =
    let
        error =
            case model.error of
                Just error ->
                    text <| toString error

                Nothing ->
                    text ""
    in
        [ row TestTitle
            [ padding 30, center ]
            [ text "Web3.Eth.Accounts"
            , column None [ alignRight ] [ error ]
            ]
        ]


view : Model -> Element Styles Variations Msg
view model =
    column None
        [ width fill, scrollbars ]
        (titleRow model ++ viewAccountTests model)


type Msg
    = InitCreate
    | Entropy String
    | InitCreateWithEntropy
    | Create (Result Error Account)
    | SignMsg (Result Error SignedMsg)
    | SignTx (Result Error SignedTx)
    | HashMessage (Result Error Sha3)
    | RecoverMsg (Result Error Address)
    | RecoverTx (Result Error Address)
    | Encrypt (Result Error Keystore)
    | Decrypt (Result Error Account)


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        InitCreate ->
            model ! [ Task.attempt Create Accounts.create ]

        Entropy entropyString ->
            { model | entropy = entropyString } ! []

        InitCreateWithEntropy ->
            model ! [ Task.attempt Create <| Accounts.createWithEntropy model.entropy ]

        Create result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok account ->
                    { model | newAccount = Just account }
                        ! [ Task.attempt SignMsg <| Accounts.sign account "Only the madman is absolutely sure."
                          , Task.attempt SignTx <| Accounts.signTransaction account config.txParams
                          , Task.attempt HashMessage <| Accounts.hashMessage "You are precisely as big as what you love and precisely as small as what you allow to annoy you."
                          , Task.attempt Encrypt <| Accounts.encrypt account "much strong passwords wowz"
                          ]

        SignMsg result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok signedMsg ->
                    { model | signedMsg = Just signedMsg }
                        ! [ Task.attempt RecoverMsg <| Accounts.recoverMsg signedMsg ]

        SignTx result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok signedTx ->
                    { model | signedTx = Just signedTx }
                        ! [ Task.attempt RecoverTx <| Accounts.recoverTx signedTx ]

        HashMessage result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok msg ->
                    { model | hashedMessage = Just msg } ! []

        RecoverMsg result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok address ->
                    { model | recoveredMsgAddress = Just address } ! []

        RecoverTx result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok address ->
                    { model | recoveredTxAddress = Just address } ! []

        Encrypt result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok keystore ->
                    { model | encryptedAccount = Just keystore }
                        ! [ Task.attempt Decrypt <| Accounts.decrypt keystore "much strong passwords wowz" ]

        Decrypt result ->
            case result of
                Err err ->
                    { model | error = Just err } ! []

                Ok account ->
                    { model | decryptedKeystore = Just account } ! []
