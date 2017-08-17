# <img src="https://cdn.rawgit.com/cmditch/elm-web3/master/elm-web3-logo.svg" width="75"> elm-web3
###### Feed the tree some ether.

## Be wary! Still under heavy development. 
Alpha release will be ready near the beginning of September '17   
Examples are under constant change. As it stands, they are more like testbeds than examples.

#### Task List
* Attain full coverage of usuable web3 functions (very close to this).
* Refine types and decoders to account for differences between various networks (Mainnet, Ropsten, Kovan, TestRPC, etc.)
* Create test harness. This will be an immense undertaking. See [wiki](https://github.com/cmditch/elm-web3/wiki/Testing-elm-web3) .
* Refine Error type, and what the native code returns. This will also be quite an undertaking.
* Reach out to experienced web3/functional programmers for feedback on API
* Document, evaluate, and refactor Web3.js Native file. This will be under refinement for some time, as it's complexity and inherent coupling to web3's nuances is vast.

```
git clone https://github.com/cmditch/elm-web3.git
cd elm-web3/
npm run lightbox-build && npm run web
```
open localhost:8000/examples in browser

### Development:
To run a live-reload server of the examples, first install elm live:
```bash
npm install -g elm-live
```
Then start the dev server:
```bash
npm run lightbox-live
```
This should open the page in your browser. If not open: http://localhost:1234/
