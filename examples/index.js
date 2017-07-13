var elm = Elm.Main.embed(document.getElementById("app"));

elm.ports.request.subscribe( function(data) {
  console.log(data);
  web3Func = eval("web3." + data.func);
  web3Func.apply(null,
    data.args.concat( (e,r) =>
      {
        elm.ports.response.send( { id: data.id, data: JSON.stringify(r) } );
        stringyResponse = JSON.stringify(r);
        console.log("Type of response: ", typeof r)
        console.log("Type of JSON.stringify(response): ", typeof stringyResponse);
        console.log("Raw response: ", r);
        console.log("JSON.stringify(response): ", r);
      }
    )
  );
});

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("https://mainnet.infura.io/metamask:8545"));
  }
});
