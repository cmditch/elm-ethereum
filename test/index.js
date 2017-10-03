var elm = Elm.Main.embed(document.getElementById("app"));

window.addEventListener('load', function() {
  // window.web3 = new Web3(new Web3.providers.HttpProvider("https://mainnet.infura.io/metamask:8545"));
  window.web3 = new Web3("ws://localhost:8545");
});
