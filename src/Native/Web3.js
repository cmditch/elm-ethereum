// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.
// This file handles the core interaction with web3.js

var _cmditch$elm_web3$Native_Web3 = function() {

    window.eventRegistry = {};

    var config = {
        web3BigNumberFields: ["totalDifficulty", "difficulty", "value", "gasPrice"],
        error: {
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
        console.log("To task: ", request);
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {
                var web3Callback = function(e,r) {
                    var result = handleWeb3Response({
                        response: r,
                        error: e,
                        decoder: request.expect.responseToResult
                    });
                    console.log("Async result: ", result)
                    if (result.ctor === "Ok") {
                        return callback(_elm_lang$core$Native_Scheduler.succeed(result._0));
                    } else if (result.ctor === "Err") {
                        return callback(_elm_lang$core$Native_Scheduler.fail(
                            { ctor: 'Error', _0: result._0 }
                        ));
                    }
                }; // web3Callback

                var func = eval("web3." + request.func);

                if (request.callType.ctor === "Async") {
                    func.apply(null, request.args.concat( web3Callback ));
                } else if (request.callType.ctor === "Sync") {
                    var web3Response = func.apply(null, request.args);
                    var result = handleWeb3Response({
                        response: r,
                        error: null,
                        decoder: undefined
                    });
                    console.log("Sync result: ", result)
                    if (result.ctor === "Ok") {
                        return callback(_elm_lang$core$Native_Scheduler.succeed(result._0));
                    } else if (result.ctor === "Err") {
                        return callback(_elm_lang$core$Native_Scheduler.fail(
                            { ctor: 'Error', _0: result._0 }
                        ));
                    }
                };
            } catch (e) {
                console.log(e);
                return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: "Tried and caught: " + e.toString() }));
            }
        });
    };


    function contractGetData(r) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {
                var response =
                    eval("web3.eth.contract("
                          + r.abi
                          + ").getData("
                          + r.constructorParams.join()
                          + ", {data: '"
                          + r.data
                          + "'})"
                    )
                console.log(response)
                return callback(_elm_lang$core$Native_Scheduler.succeed(response));
            } catch(e) {
                console.log(e)
                return callback(_elm_lang$core$Native_Scheduler.fail(
                    {ctor: 'Error', _0: "Contract.getData failed - " + e.toString() }
                ));
            }
        });
    };


    function watchEvent(e){
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {
                var registry = window.eventRegistry;
                registry[e.portName] =
                    eval("web3.eth.contract("
                          + e.abi + ").at('"
                          + e.address
                          + "')."
                          + e.eventName
                          + "("
                          + JSON.stringify(e.eventParams)
                          + ","
                          + JSON.stringify(e.filterParams)
                          + ")"
                    ); // Or we could do .apply() after the eval to avoid stringify?
                var port = eval("window.elmShim.ports." + e.portName);
                registry[e.portName].watch(function(e,r) { console.log( formatLog(r) )});
                registry[e.portName].watch(function(e,r) { port.send( formatLog(r) )});
                return callback(_elm_lang$core$Native_Scheduler.succeed());
            } catch (e) {
                return callback(_elm_lang$core$Native_Scheduler.fail(
                    {ctor: 'Error', _0: "Event sub failed - " + e.toString() }
                ));
            }
        });
    };


    function reset(keepIsSyncing){
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {
                eval("web3.reset(" + keepIsSyncing.toString() + ")")
                return callback(_elm_lang$core$Native_Scheduler.succeed());
            } catch (e) {
                return callback(_elm_lang$core$Native_Scheduler.fail(
                    {ctor: 'Error', _0: "Event reset failed - " + e.toString() }
                ));
            }
        });
    };

    /*
    // Most web3 requests from Elm have an 'Expect' function or decoder attached.
    // The user should not have to worry about all the nuances of decoding web3 responses.
    // The function below allows for this trickery to occur, in combination with Web3.Internal.elm
    */
    function expectStringResponse(responseToResult) {
        return {
            responseToResult: responseToResult
        };
    };

    // (Error, Response, Expect/Decoder) -> Result Err Ok
    function handleWeb3Response(r) {
        if (r.error !== null) {
            return {ctor: "Err", _0: r.error }
        } else if (r.response === null) {
            return {ctor: "Err", _0: config.error.nullResponse }
        } else if (r.response === undefined) {
            return { ctor: "Err", _0: config.error.undefinedResposnse }
        } else if (r.decoder !== undefined){
            // decoder returns a Result
            return r.decoder( formatWeb3Response(r.response) )
        } else {
            return { ctor: 'Ok', _0: r.response }
        }
    };

    /*
    // Check each response from web3 for BigNumber values and convert to fixed string.
    // JSON.stringify all values from web3 before sending to Elm.
    */
    function formatWeb3Response(r) {
        if (r.isBigNumber) { return JSON.stringify(r.toFixed()) }
        config.web3BigNumberFields.forEach( val => {
            if (r[val] !== undefined && r[val].isBigNumber) {
                r[val] = r[val].toFixed();
            }
        });
        return JSON.stringify(r);
    };


    function formatLog(log) {
        Object.keys(log.args).forEach(function(arg) {
            log.args[arg] = formatIfBigNum(log.args[arg]);
        });
        return log;
    }


    function formatIfBigNum(value) {
        if (value.isBigNumber) {
          return value.toFixed();
        } else {
          return value;
        }
    }


    function formatLogsArray(logsArray) {
        logsArray.map(function(log) { formatLog(log) } );
        return logsArray;
    }



    return {
        toTask: toTask,
        contractGetData: contractGetData,
        watchEvent: watchEvent,
        reset: reset,
        expectStringResponse: expectStringResponse
    };

}();
