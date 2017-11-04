# <img src="https://cdn.rawgit.com/cmditch/elm-web3/master/examples/elm-web3-logo.svg" width="75"> elm-web3

###### Behold, the beauty of elm. Give it a try!
 

First Install Geth    
https://geth.ethereum.org/downloads/

Second Install Elm things    
```
npm install -g elm
npm install -g elm-live
```
Then get elm-web3 and open test/example page   
```
git clone https://github.com/cmditch/elm-web3.git
cd elm-web3/
npm run test
```
Run the local Geth testnet in a new terminal window    
To allow for tests involving tx's and subscriptions mine a little.    
NOTE: It takes a while to build the DAG and start mining on your first go.    
Give it a minute or three. :smiley:
```
npm run testnet
miner.start(4)
```

open http://localhost:8000/test     

------    

## Time traveling debugger    
![alt text](https://raw.githubusercontent.com/cmditch/elm-web3/master/examples/accounts-with-debugger.png)    

## Code/Pages for every function in web3 
![alt text](https://raw.githubusercontent.com/cmditch/elm-web3/master/examples/wallet.png)    

------    

Still a number of big things to tick off the list:
- Getting setup with elm-grove or elm-github-install
- Documentation
- Example App
- Code Generator for Elm interfaces to Contracts (in Haskell 😄 )
- Revising Types / Decoders in the face of Byzantium changes
- Better tests. More automated, and without reliance on browser.
- Fixing a few quirks here there, some of which are issues with web3.js 1.0    

###### Feed the tree some ether  
### 🌳Ξ🌳Ξ🌳

