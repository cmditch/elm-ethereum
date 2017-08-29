function contractMethod(request)
{
    var contract = eval("new web3.eth.Contract(" + request.abi + ",'" request.address + "')")
    eval("contract.methods['" + request.method + "'].apply(null," + JSON.stringify(request.args) + ").call(callback)")
}
