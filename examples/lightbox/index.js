// window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
var elm = Elm.Main.embed(document.getElementById("app"));
callback = (e,r) => console.log(e,r)
request = {
    address : '0xa10b5565C1f5d9Ca24c990104Ea28171727ab3A6',
    abi : [{"constant":false,"inputs":[],"name":"uintArray","outputs":[{"name":"","type":"uint256[23]"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"otherNum","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"n","type":"uint256"}],"name":"mutateSubtract","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint8"},{"name":"b","type":"uint8"}],"name":"add_","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"someNum","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"n","type":"int8"}],"name":"mutateAdd","outputs":[{"name":"","type":"int8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"uintArray","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"inputs":[{"name":"someNum_","type":"int8"}],"payable":true,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"mathematician","type":"address"},{"indexed":false,"name":"sum","type":"int8"}],"name":"Add","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"professor","type":"address"},{"indexed":false,"name":"numberz","type":"uint256"},{"indexed":false,"name":"aPrime","type":"int256"}],"name":"Subtract","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"uintArray","type":"uint256[23]"}],"name":"UintArray","type":"event"}]
}





window.addEventListener('load', function() {
  window.web3 = new Web3(new Web3.providers.HttpProvider("https://ropsten.infura.io/metamask:8545"));
  contract = eval( "new web3.eth.Contract(" + JSON.stringify(request.abi) + ",'" + request.address + "')" )
  eval("contract.methods['add_'].apply(null,[10,13]).call(callback)")
});
