# elm-ethereum complex example 
### Single Page Decentralized App (SPDA)

```bash
git clone git@github.com:cmditch/elm-ethereum.git
cd elm-ethereum/examples/complex
npm reinstall
npm run dev

open http://localhost:8080
```

App includes:

* Use of Style Elements Library
* SPA Navigation (Route Handling / URL Parser / Browser History)
* Msg passing between pages (see [elm-spa-example](https://github.com/rtfeldman/elm-spa-example/) for similar architecture)
* Use of [elm-ethereum-generator](https://github.com/cmditch/elm-ethereum-generator/) for (Contract ABI -> Elm) Help
* Eth.Sentry.ChainCmd for help with SPA Msg passing
* Eth.Sentry.Tx for Wallet Integration and Tx sending
* Eth.Sentry.Event for Event listening over websockets
* Eth.Sentry.Wallet for Wallet Info (Account, NetworkId)
* UPort Integration Demo (With some JWT action)
