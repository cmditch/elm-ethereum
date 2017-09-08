# <img src="https://cdn.rawgit.com/cmditch/elm-web3/master/elm-web3-logo.svg" width="75"> elm-web3
###### Feed the tree some ether.

## Be wary! Still under heavy development.
Much time was inadvertently spent wrapping web3.js 0.20.1 on master branch    
Efforts being spent supporting the new web3.js 1.0 API    
Alpha release will be ready mid October '17   

#### Task List
* Attain full coverage of usuable web3 functions (very close to this).
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
