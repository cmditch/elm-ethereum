# <img src="https://cdn.rawgit.com/cmditch/elm-web3/master/examples/elm-web3-logo.svg" width="75"> elm-web3

## Update on Progress
Currently `elm-web3` is going through a big rewrite. A "pure Elm" implementation is in the works, which can safely live on the Elm package manager, along with all it's documentation.

This was inspired by the recent news regarding the discontinuation of user generated native/kernel code in the upcoming release of elm 0.19.

I will leave the 0.18 version of the library on a separate branch, where development can continue if desired.

### Good News: 
New version should be less prone to bugs, more accessible documentation, and full use of elm's tooling and package manager.
### Bad News:
More boiler plate, and tricky asynchronicty to deal with in using ports.

## What this means for the future of elm + ethereum:  
  - No longer coupled to web3.js  
  - Should be a bit faster, since raw RPC responses are decoded in pure elm, and not by web3.js then into elm.  
  - Stronger safety guarantees, as we have the full confidence of elm's compiler behind the code, with no JS dependencies.
  - Talking to metamask will have to be done through ports
  - The contract event subscription module will require similar boilerplate as [elm-phoenix-socket](http://package.elm-lang.org/packages/fbonetti/elm-phoenix-socket/latest)
  - Less task chaining, due to asynchronicity brought by ports.
  



###### Feed the tree some ether  
### 🌳Ξ🌳Ξ🌳

