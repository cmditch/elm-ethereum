var elm_ethereum_ports = require('elm-ethereum-ports');

const {Elm} = require('./Main');
var node = document.getElementById("elm-app")

window.addEventListener('load', function () {
    if (typeof web3 !== 'undefined') {
        web3.version.getNetwork(function (e, networkId) {
            app = Elm.Main.init({flags: parseInt(networkId), node: node});
            elm_ethereum_ports.txSentry(app.ports.txOut, app.ports.txIn, web3);
            elm_ethereum_ports.walletSentry(app.ports.walletSentry, web3);
            ethereum.enable();
        });
    } else {
        app = Elm.Main.init({flags: 0, node: node});
        console.log("Metamask not detected.");
    }
});