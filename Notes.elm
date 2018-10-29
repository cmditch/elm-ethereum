module Notes exposing (..)

{-| TO-DO

  - Rework Sentry.Event
      - initHttp, initWebsocket
      - HTTP will have to handle filter installation, clearing, polling.
      - withDebug, takes Debug.log from user

  - Rework Abi.Encode
      - Support various uint, int, and byte sizes
      - Fail upon overflows

  - Use more generic error type
      - Helps caputure cases like uint overflows above

  - Update elm-ethereum-generator
      - Better parser
      - Dynamic types

  - Make 0.19 compatible
      - Remove Debug.logs
      - Replace any flip, (%), etc.
      - Fix var shadowing

  - Allow parsing events from TxReceipts

  - Create Encode/Decode modules, make all that private stuff public.

  - Change all BigInt.fromString to BigInt.fromHexString where necessary.

-}


a =
    1
