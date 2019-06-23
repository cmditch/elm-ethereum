'use strict';

// Tx Sentry - Send and listen to transactions form elm to web3 provider
function txSentry(fromElm, toElm, web3) {
    checkFromElmPort(fromElm);
    checkToElmPort(toElm);
    checkWeb3(web3);

    fromElm.subscribe(function (txData) {
        try {
            web3.eth.sendTransaction(txData.txParams, function (e, r) {
                toElm.send({ ref: txData.ref, txHash: r || e });
            });
        } catch (error) {
            console.log(error);
            toElm.send({ ref: txData.ref, txHash: null });
        }
    });
}

// Wallet Sentry - listen to account and network changes
function walletSentry(toElm, web3) {
    checkToElmPort(toElm);
    checkWeb3(web3);
    var model = { account: null, networkId: 0 };
    getNetworkAndAccount(web3, sendModelToElm(toElm, model)) // Make initial call for data.
    setInterval(function () { getNetworkAndAccount(web3, sendModelToElm(toElm, model)) }, 500); // Repeat on half second interval.
}

// Helper function that calls out to web3 for account/network
function getNetworkAndAccount(web3, callback) {
    web3.version.getNetwork(function(netError, networkId) {
        web3.eth.getAccounts(function (accountError, accounts) {
            if (netError) { console.log("web3.version.getNetwork Error: ", netError);}
            if (accountError) { console.log("web3.eth.getAccounts Error: ", accountError)}
            callback( {account: accounts[0], networkId: parseInt(networkId)} );
        });
    });
}

// Updates model and sends to Elm if anything has changed. Curried to make callback easier.
function sendModelToElm(toElm, globalModel) {
    return function (newModel) {
        if (newModel.account !== globalModel.account || newModel.networkId !== globalModel.networkId) {
            globalModel = newModel;
            toElm.send(globalModel);
        }
    }
}

// Logging Helpers

function checkToElmPort(port) {
    if (typeof port === 'undefined' || typeof port.send === 'undefined') {
        console.warn('elm-ethereum-ports: The port to send messages to Elm is malformed.')
    }
}

function checkFromElmPort(port) {
    if (typeof port === 'undefined' || typeof port.subscribe === 'undefined') {
        console.warn('elm-ethereum-ports: The port to subscribe to messages from Elm is malformed.')
    }
}

function checkWeb3(web3) {
    if (typeof web3 === 'undefined' || typeof web3.version === 'undefined' || typeof web3.eth === 'undefined') {
        console.warn('elm-ethereum-ports: web3 object is undefined, or web3.version or web3.eth is missing')
    }
}

exports.txSentry = txSentry;
exports.walletSentry = walletSentry;
