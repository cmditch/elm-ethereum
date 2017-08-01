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
                        console.log("Err within Async found!", result)
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
                    console.log("Sync result: ", result);
                    if (result.ctor === "Ok") {
                        return callback(_elm_lang$core$Native_Scheduler.succeed(result._0));
                    } else if (result.ctor === "Err") {
                        return callback(_elm_lang$core$Native_Scheduler.fail(
                            { ctor: 'Error', _0: result._0 }
                        ));
                    }
                };
            } catch (e) {
                console.log("Try/Catch error on toTask", e);
                return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: "Tried and caught: " + e.toString() }));
            }
        });
    };


    function contractGetData(r) {
        console.log("contractGetData: ", r);
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
                console.log("Try/Catch error on contractGetData", e);
                return callback(_elm_lang$core$Native_Scheduler.fail(
                    {ctor: 'Error', _0: "Contract.getData failed - " + e.toString() }
                ));
            }
        });
    };


    function watchEvent(e){
        console.log("watchEvent: ", e);
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {
                var registry = window.eventRegistry;
                if (registry[e.portName]) { registry[e.portName].stopWatching() }; // Clear duplicate 'watchings' instantiation.
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
                console.log(window.eventRegistry);
                return callback(_elm_lang$core$Native_Scheduler.succeed());
            } catch (e) {
                console.log("Try/Catch error on watchEvent", e);
                return callback(_elm_lang$core$Native_Scheduler.fail(
                    {ctor: 'Error', _0: "Event sub failed - " + e.toString() }
                ));
            }
        });
    };


    function reset(keepIsSyncing){
        console.log("web3.reset called");
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {
                eval("web3.reset(" + keepIsSyncing.toString() + ")")
                console.log(window.eventRegistry);
                return callback(_elm_lang$core$Native_Scheduler.succeed());
            } catch (e) {
                console.log("Try/Catch error on web3.reset", e);
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


/*
//  Run on all web3 repsonses.
//  (error, response, Expect/Decoder function) -> Result Err Ok
*/
    function handleWeb3Response(r) {
        console.log("handleWeb3Response: ")
        if (r.error !== null) {
            console.log("Web3 response error: ",r);
            return {ctor: "Err", _0: r.error.message.split("\n")[0] }
        } else if (r.response === null) {
            console.log("Web3 response was null: ", r);
            return {ctor: "Err", _0: config.error.nullResponse }
        } else if (r.response === undefined) {
            console.log("Web3 response was undefined: ", r);
            return { ctor: "Err", _0: config.error.undefinedResposnse }
        } else if (r.decoder !== undefined){
            console.log("Web3 was async w/ decoder: ", r);
            // decoder returns a Result
            return r.decoder( formatWeb3Response(r.response) )
        } else {
            console.log("Web3 was sync: ", r);
            return { ctor: 'Ok', _0: r.response }
        }
    };


/*
//  Run on all async web3 repsonses.
//  Turns BigNumber into full strings.
//
*/
    function formatWeb3Response(r) {
        console.log("formatWeb3Response executed (remove bigNums for async ) ");
        if (r.isBigNumber) { return JSON.stringify(r.toFixed()) }
        config.web3BigNumberFields.forEach( val => {
            if (r[val] !== undefined && r[val].isBigNumber) {
                r[val] = r[val].toFixed();
            }
        });
        return JSON.stringify(r);
    };


/*
//  Run on all web3 event repsonses (logs).
//  Turns BigNumber into full strings.
*/
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
