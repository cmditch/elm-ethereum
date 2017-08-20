// window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
var elm = Elm.Main.embed(document.getElementById("app"));

// elm app shim for passing contract back through ports in native code
window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    // window.web3 = new Web3(new Web3.providers.HttpProvider("https://ropsten.infura.io/metamask:8545"));
    window.web3 = new Web3(new Web3.providers.HttpProvider("https://ropsten.infura.io/metamask:8545"));
  }
});
