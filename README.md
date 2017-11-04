# <img src="https://cdn.rawgit.com/cmditch/elm-web3/master/elm-web3-logo.svg" width="75"> elm-web3

###### Behold, the beauty of elm. Give it a try!

## Installation  
If needed, install the Elm things
```
npm install -g elm elm-live elm-github-install
```
then add 
```
 "dependency-sources": { "cmditch/elm-web3": "https://github.com/cmditch/elm-web3" }
``` 
to your `elm-package.json` and `elm-install`.

See [here](https://github.com/cmditch/elm-web3/blob/master/test/elm-package.json) for an example. 

## Example App
First Install Geth    
https://geth.ethereum.org/downloads/

```
git clone https://github.com/cmditch/elm-web3.git
cd elm-web3/test
npm run test
```

Then get elm-web3 and open test/example page   

Run the local Geth testnet in a new terminal window    
Turn on mining to test txs/subscriptions.   
NOTE: DAG takes a bit of time to build on the first run.  
```
npm run testnet
miner.start() // within geth console
```

open http://localhost:8000/    

------    

## Time traveling debugger    
![alt text](https://raw.githubusercontent.com/cmditch/elm-web3/master/accounts-with-debugger.png)    

## Code/Pages for every function in web3 
![alt text](https://raw.githubusercontent.com/cmditch/elm-web3/master/wallet.png)    

------    

Still a number of big things to tick off the list:
- Documentation
- Example App(s)
- Code Generator for Elm interfaces to Contracts (in Haskell 😄 )
- Revising Types / Decoders in the face of Byzantium changes
- Better tests. More automated, and without reliance on browser. 

###### Feed the tree some ether  
### 🌳Ξ🌳Ξ🌳

