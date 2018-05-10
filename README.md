# <img src="https://cdn.rawgit.com/cmditch/elm-ethereum/master/elm-ethereum-logo.svg" width="75"> elm-ethereum

DApps in Pure Elm

More examples and docs are in the works!

This library allows you to interact with the Ethereum blockchain much like `purescript-web3`, `ethers.js`, or `web3.js`.
You can hook into web wallets like MetaMask and send transactions, as well as perform read-only operations off an Ethereum node.

See [why elm?](#why-elm)

## Setup

1. **Import** the `Eth` module and it's types.

    ```elm
    import Eth
    import Eth.Types exposing (..)
    ```

2. **Define** your endpoint

    It's good to keep the node url in your model. This way it can be kept in sync with MetaMask.    
    Example code of this "sync" pattern to come.

    ```elm
    type alias Model =
      { ethHttpNode : HttpProvider }
    
    init =
      { ethHttpNode = "https://mainnet.infura.com/" }
    ```

3. **Simple** - Look at the blockchain.

    ```elm
    getMyBalanceInHistory : Int -> Task Http.Error BigInt
    getMyBalanceInHistory blockNum =
        Eth.getBalanceAtBlock model.ethHttpNode myAddress (BlockNum blockNum)
    ```

4. **Advanced** - Chain tasks together.

    Get all newly created contract addresses in the latest block.    
    In a few lines of code.    

    ```elm
    findNewestContracts : Cmd Msg
    findNewestContracts =
        Eth.getBlockNumber model.ethHttpNode
            |> Task.andThen (Eth.getBlock model.ethHttpNode)
            |> Task.andThen
                (\block ->
                    block.transactions
                        |> List.map (Eth.getTxReceipt model.ethHttpNode)
                        |> Task.sequence
                )
            |> Task.map (List.map .contractAddress >> MaybeExtra.values)
            |> Task.attempt MostRecentContracts
    ```

    Do not fret if the above looks perplexing. This is fairly advanced Elm. Lots is going on here.    
    Partial function application. Function composition. Maps within maps. Record accessor sugar.    
    The point is, your code can be terse, expressive, with great error handling baked in.    



## Why Elm?

If one were to sum up the experience of programming in Elm in two words: **Fearless Refactoring**    
This is by no means the only pleasantry Elm has to offer.   

Elm's claim to fame is zero runtime exceptions. Elm's compiler and static types are your best friends.    
Both from an error catching standpoint, but just as importantly from a domain modeling perspective.    

Elm's "Union types" or "ADT's" allow you to fully leverage the compiler when modeling your business domain.    
See [BlockId](http://package.elm-lang.org/packages/cmditch/elm-ethereum/latest/Eth-Types#BlockId) or [NetworkId](http://package.elm-lang.org/packages/cmditch/elm-ethereum/latest/Eth-Net#NetworkId) for instance.

### Why else?
  - **Simplicity and cohesion**
```
    Javascript                    Elm
    ---------------------------------
    npm/yarn                 built in
    Webpack                  built in
    React                    built in
    Redux                    built in
    Typescript/Flow          built in
    Immutable.JS             built in
```
  - **Phenomenal tooling and resources**

     [**Time traveling debugger**](http://elm-lang.org/blog/the-perfect-bug-report) - Import/Export history. QA like a champ.    
     [**elm-format**](https://github.com/avh4/elm-format) - Adds up to hours of tedius "work" saved.    
     [**elm-reactor**](https://github.com/elm-lang/elm-reactor) - Nice dev server.    
     [**elm-test**](http://package.elm-lang.org/packages/elm-community/elm-test/latest) - Fuzz testing == legit.   
     [**elm-benchmark**](http://package.elm-lang.org/packages/BrianHicks/elm-benchmark/latest) - Clone this package and give it a whirl.     
     [**Elm Package and Docs**](http://package.elm-lang.org/) - Pleasant and consistent. Enforced semantic versioning.    

  - **Strong static types**

     Find errors fast with readable compiler messages.    
     Less [millions lost](https://twitter.com/a_ferron/status/892350579162439681?lang=en) from typos.

  - **No null or undefined**

     Never miss a potential problem.

  - **Purely functional**

     Leads to decoupled and easily refactorable code.

  - **Great Community**

     Kind. Responsive. Thoughtful. Intelligent.


## Contributing

Pull requests and issues are greatly appreciated!    
If you think there's a better way to implement parts of this library, I'd love to hear your feedback.

###### Feed the tree some ether

### 🌳Ξ🌳Ξ🌳