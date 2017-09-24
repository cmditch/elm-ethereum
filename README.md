# <img src="https://cdn.rawgit.com/cmditch/elm-web3/master/elm-web3-logo.svg" width="75"> elm-web3
###### Feed the tree some ether.

## Be wary! Still under heavy development.
Much time was inadvertently spent wrapping web3.js 0.20.1 on master branch    
Efforts being spent supporting the new web3.js 1.0 API    
Alpha release will be ready November '17   

#### Task List
* Attain full coverage of usuable web3 functions (very close to this).
* Refine Error type, and what the native code returns. This will also be quite an undertaking.
* Reach out to experienced web3/functional programmers for feedback on API
* Document, evaluate, and refactor Web3.js Native file. This will be under refinement for some time, as it's complexity and inherent coupling to web3's nuances is vast.

Install Elm things    
```
npm install -g elm
npm install -g elm-live
```
then get elm-web3 and open test/example page   
```
git clone https://github.com/cmditch/elm-web3.git
cd elm-web3/
git checkout 1.0
npm run test
```
open http://localhost:8000/test   
