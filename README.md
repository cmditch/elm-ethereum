# <img src="https://cdn.rawgit.com/cmditch/elm-web3/master/examples/elm-web3-logo.svg" width="75"> elm-web3

## Fair word of caution
Since MetaMask does not support web3.js 1.0 yet, using elm-web3 in production is difficult at best, downright impossible at worst. Hopefully MetaMask will support this soon! Once they do, Elm + Ethereum will reign the day!  

The code generator to help provide easy Elm interfaces for Solidity contracts is in the works too. Fear not!

## Installation  
If needed, install the Elm things
```
npm install -g elm elm-live elm-github-install
```
then add to your `elm-package.json` 
```
 "dependency-sources": { "cmditch/elm-web3": "https://github.com/cmditch/elm-web3" }
``` 
and run `elm-install`.

See [here](https://github.com/cmditch/elm-web3/blob/master/test/elm-package.json) for an example. 

## Example App
First Install Geth    
https://geth.ethereum.org/downloads/

```
git clone https://github.com/cmditch/elm-web3.git
cd elm-web3/test
npm run test
```
Run the local Geth testnet in a new terminal window    
Turn on mining to test txs/subscriptions.   
NOTE: DAG takes a bit of time to build on the first run.  
```
npm run testnet
miner.start() // within geth console
```

Open http://localhost:8000/    

------    

## Time traveling debugger    
![alt text](https://raw.githubusercontent.com/cmditch/elm-web3/master/examples/accounts-with-debugger.png)    

## Code/Pages for every function in web3 
![alt text](https://raw.githubusercontent.com/cmditch/elm-web3/master/examples/wallet.png)    

------    

Still a number of big things to tick off the list:
- Documentation
- Example App(s)
- Code Generator for Elm interfaces to Contracts (in Haskell 😄 )
- Revising Types / Decoders in the face of Byzantium changes
- Better tests. More automated, and without reliance on browser. 

###### Feed the tree some ether  
### 🌳Ξ🌳Ξ🌳

