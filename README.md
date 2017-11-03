# <img src="https://cdn.rawgit.com/cmditch/elm-web3/master/elm-web3-logo.svg" width="75"> elm-web3

###### Behold, the beauty of elm. Give it a try!
 

First Install Geth    
https://geth.ethereum.org/downloads/

Second Install Elm things    
```
npm install -g elm elm-live elm-github-install
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
miner.start()
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

