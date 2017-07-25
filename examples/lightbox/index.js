var elm = Elm.Main.embed(document.getElementById("app"));

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
  }
});


var abi = [{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"someNum","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"n","type":"int8"}],"name":"mutateAdd","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint8"},{"name":"b","type":"uint8"}],"name":"add","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"inputs":[{"name":"someNum_","type":"int8"}],"payable":true,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"mathematician","type":"address"},{"indexed":false,"name":"sum","type":"int8"}],"name":"Add","type":"event"}]
var address = "0xeb8f5983d099b0be3f78367bf5efccb5df9e3487"

var log = (e,r) => console.log(e,r);
var contract, filter, watch;

setTimeout( () => {
    contract = web3.eth.contract(abi).at(address);
    filter = contract.Add;
    watch = filter({}).watch(log);
  }
, 1000)
