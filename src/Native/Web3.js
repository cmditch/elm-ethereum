// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.
// This file handles the core interaction with web3.js

var _cmditch$elm_web3$Native_Web3 = function() {

    const config = {
        web3BigNumberFields: ["totalDifficulty", "difficulty", "value", "gasPrice"],
        timeoutInMs: 90000,
        error: {
            // TODO should timeout be it's own error type? Probably not, since only deployContract can timeout currently.
            timeoutError: "Transaction timeout. Mining failed or network took to long. TxId: ",
            nullResponse: "Web3 responded with null. Check your parameters. Non-existent address, or unmined block perhaps?",
            undefinedResposnse: "Web3 responded with undefined.",
            deniedTransaction: "MetaMask Tx Signature: User denied transaction signature.",
            unknown: "Unknwown till further testing is performed."
        }
    };

// TODO   Deal with "Web3 responded with undefined." (Transaction cancelled usually),
//        and"Error: invalid address" (MetaMask was not unlocked...)

// TODO Return a tuple of errors, where: (simpleDescription, fullConsoleOutput)

    function toTask(request) {
        console.log(request);
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {
                var f = eval("web3." + request.func);
                f.apply(null,
                    // Args passed from elm are always appended with an Error-First style callback,
                    // in order to satisfy web3's aysnchronus by design nature.
                    request.args.concat( (e, r) =>  {
                        // Map response errors to error type
                        if (r === null) {
                            return callback(_elm_lang$core$Native_Scheduler.fail(
                                { ctor: 'Error', _0: config.error.nullResponse }
                            ));
                        } else if (r === undefined) {
                        // This will execute when using metamask and 'rejecting' a tx.
                            return callback(_elm_lang$core$Native_Scheduler.fail(
                                { ctor: 'Error', _0: config.error.undefinedResposnse }
                            ));
                        }
                        // Decode the payload using Elm function passed to Expect
                        var result = request.expect.responseToResult( formatWeb3Response(r) );
                        console.log(result);
                        if (result.ctor !== 'Ok') {
                            // resolve with decoding error
                            return callback(_elm_lang$core$Native_Scheduler.fail(
                                {ctor: 'BadPayload', _0: result._0}
                            ));
                        }
                        // success
                        return callback(_elm_lang$core$Native_Scheduler.succeed(result._0));
                    })
                );
            } catch (e) {
                console.log(e);
                return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: e.toString() }));
            }
        });
    };


    /*
    // This should be refactored and might be able to use the more general toTask above.
    // If we implement the timeoutable Task.AndThen pattern within elm.
    // MyContract.new.getData(ctor1, ctor2, {data: '0x12312'}) -> sendTransaction({data, gas, etc}) -> listenForMinedContract
    */
    function deployContract(deployFunc){
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {
                console.log("Request Object: ", deployFunc);

                // Throw error if wallet doesn't exist
                if (web3.eth.accounts[0] == undefined) {
                    return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'NoWallet' }));
                };

                // Throw error if tx takes longer than timeout
                function startTimeout(contract) {
                  var txId = "Error fetching txId.";
                  if (contract !== undefined) { txId = contract.transactionHash };
                  setTimeout( () => { return callback(_elm_lang$core$Native_Scheduler.fail(
                        { ctor: 'Error', _0: config.error.timeoutError + txId }
                    ))}
                    , config.timeoutInMs
                )}

                // This is called through the contract eval statement config'd in elm
                function metaMaskCallBack(e, contract) {
                    try {
                        // Ignore first callback of unmined contract
                        if (e === null && contract.address === undefined) {
                            startTimeout(contract);
                            console.log("TxId: " + contract.transactionHash);
                            console.log("Time: " + new Date().getTime() );
                            return
                        // Succeed on mined contract
                      } else if (e === null && contract.address !== undefined) {
                            return callback(_elm_lang$core$Native_Scheduler.succeed(
                                { txId: contract.transactionHash, address: contract.address }
                            ));
                        // Fail on error
                        } else {
                            console.log("e !== null, inside the 'else' return in callBack conditional: ");
                            console.log(e);
                            var err = e.toString()
                            return callback(_elm_lang$core$Native_Scheduler.fail(
                                // TODO Return a tuple of errors, where: (simpleDescription, fullConsoleOutput)
                                { ctor: 'Error', _0: err.split("\n")[0] }
                            ));
                        }
                    } catch(e) {
                        console.log("Inside the catch during metaMaskCallBack:  ");
                        console.log(e);
                        return callback(_elm_lang$core$Native_Scheduler.fail(
                            { ctor: 'Error', _0: e.toString() }
                        ));
                    }
                };
                // Eval contract data + metaMaskCallBack
                var contract = eval("web3." + deployFunc);
                console.log("Eval'd Contract: ", contract);
            } catch (e) {
                console.log("Inside the catch during deployWallet:  ");
                console.log(e);
                return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: "Denied Transaction?" }));
            }
        });
    };


    /*
    //TODO Implement event watching and event stopping.
    */
    function eventsHandler(){

    };


    /*
    // All web3 requests from Elm have an 'Expect' function or decoder attached.
    // The user should not have to worry about all the nuances of decoding web3 responses.
    // The function below allows for this trickery to occur, in combination with Web3.Internal.elm
    */
    function expectStringResponse(responseToResult) {
        return {
            responseToResult: responseToResult
        };
    };


    /*
    // Check each response from web3 for BigNumber values and convert to fixed string.
    // JSON.stringify all values from web3 before sending to Elm.
    */
    function formatWeb3Response(r) {
        if (r.isBigNumber) { return r.toFixed() }
        config.web3BigNumberFields.forEach( val => {
            if (r[val] !== undefined && r[val].isBigNumber) {
                r[val] = r[val].toFixed();
            }
        });
        return JSON.stringify(r);
    };


    /*
    // Convert known BigNumber fields in event.args to fixed string.
    //
    */
    function formatEventResponse(r) {
      bigIntKeys.forEach( key => eventObj.args[key] = eventObj.args[key].toFixed() );
      return eventObj;
    };


    return {
        toTask: toTask,
        deployContract: deployContract,
        expectStringResponse: expectStringResponse
    };

}();
