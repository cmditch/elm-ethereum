# [![elm-ethereum](https://cmdit.ch/images/elm-ethereum-logo.svg)](https://github.com/cmditch/elm-ethereum) elm-ethereum

**Examples:**  
[Simple starter example](https://github.com/cmditch/elm-ethereum/tree/master/examples/simple/src/Main.elm)  
[Complex example SPA Dapp](https://github.com/cmditch/elm-ethereum/tree/master/examples/complex) 

Cool Feature:  See [here](https://github.com/cmditch/elm-ethereum/blob/master/examples/simple/src/Main.elm#L138) how you can easily track the block depth of transactions after they've been mined.

-----------------------

This library allows you to interact with the Ethereum blockchain much like `purescript-web3`, `ethers.js`, or `web3.js`.
You can hook into web wallets like MetaMask and send transactions, as well as perform read-only operations on smart contracts.

See [why elm?](#why-elm)

## Setup

- **Setup** and define your node endpoint.

```elm
    import Eth
    import Eth.Types exposing (..)


    type alias Model =
        { ethNode : HttpProvider }

    init =
        { ethNode = "https://mainnet.infura.com/" }
```

  It's good to keep the node url in your model. This way it can be kept in sync with MetaMask.
  Example code of this "sync" pattern to come.

## Examples

- **Simple** - Look at the blockchain

    Get an account balance at a specific block height.

```elm
    getMyBalanceInHistory : Int -> Task Http.Error BigInt
    getMyBalanceInHistory blockNum =
        Eth.getBalanceAtBlock model.ethNode myAddress (BlockNum blockNum)
```

- **Advanced** - Chain tasks together

    Get all newly created contract addresses in the latest block. In a few lines of code.  

```elm
    findNewestContracts : Task String (List Address)
    findNewestContracts =
        Eth.getBlockNumber model.ethNode
            |> Task.andThen (Eth.getBlock model.ethNode)
            |> Task.andThen
                (\block ->
                    block.transactions
                        |> List.map (Eth.getTxReceipt model.ethNode)
                        |> Task.sequence
                )
            |> Task.map (MaybeExtra.values << List.map .contractAddress)
            |> Task.mapError prettifyHttpError
```  

This is an example of [Railway Oriented Programming](https://fsharpforfunandprofit.com/rop/). A [great video](https://vimeo.com/113707214) by Scott Wlaschin.  

## Why Elm

I'd sum up the experience of programming in Elm with two words: **Fearless Refactoring**

This is by no means the only pleasantry the fine tree has to offer.

Elm's claim to fame is zero runtime exceptions. Its compiler and static types are your best friends. Both from an error catching standpoint, but just as importantly, from a domain modeling standpoint.  

**Union Types** allow you to fully leverage the compiler when modeling your business domain. See [BlockId](http://package.elm-lang.org/packages/cmditch/elm-ethereum/latest/Eth-Types#BlockId) or [NetworkId](http://package.elm-lang.org/packages/cmditch/elm-ethereum/latest/Eth-Net#NetworkId) for instance.  

Union types also allow you to hide implementation details by implementing "opaque types".  An [Address](https://github.com/cmditch/elm-ethereum/blob/master/src/Internal/Types.elm#L4) is just a string under the hood, but you can never directly touch that string.

### Why else

- **Simplicity and cohesion**

```text
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
     Less [millions of dollars lost](https://twitter.com/a_ferron/status/892350579162439681?lang=en) from typos.

- **No null or undefined**

     Never miss a potential problem.

- **Purely functional**

     Leads to decoupled and easily refactorable code.

- **Great Community**

     Thoughtful, responsive, intelligent, and kind.  
     Great [Slack](https://elmlang.herokuapp.com/) and [Discourse](https://discourse.elm-lang.org/).

## Contributing

Pull requests and issues are greatly appreciated!  
If you think there's a better way to implement parts of this library, I'd love to hear your feedback.


###### Feed the tree some ether
### 🌳Ξ🌳Ξ🌳
