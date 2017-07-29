// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.
// This file handles the core interaction with web3.js

var _cmditch$elm_web3$Native_Web3 = function() {

    var config = {
        web3BigNumberFields: ["totalDifficulty", "difficulty", "value", "gasPrice"],
        error: {
            // TODO should timeout be it's own error type? Probably not, since only deployContract can timeout currently.
            nullResponse: "Web3 responded with null. Check your parameters. Non-existent address, or unmined block perhaps?",
            undefinedResposnse: "Web3 responded with undefined.",
            deniedTransaction: "MetaMask Tx Signature: User denied transaction signature.",
            unknown: "Unknwown till further testing is performed."
        }
    };

    // var eventRegistry = {};

// TODO   Deal with "Web3 responded with undefined." (Transaction cancelled usually),
//        and"Error: invalid address" (MetaMask was not unlocked...)

// TODO Return a tuple of errors, where: (simpleDescription, fullConsoleOutput)

    function toTask(request) {
        console.log("BEGINNING OF TO TASK: ", request);
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {

                var web3Callback = function(e,r) {
                    // Args passed from elm are always appended with an Error-First style callback,
                    // in order to satisfy web3's aysnchronus by design nature.

                    // Map response errors to error type
                    // TODO Does this even work as intended, within this web3Callback func?

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

                    if (result.ctor !== 'Ok') {
                        // resolve with decoding error
                        return callback(_elm_lang$core$Native_Scheduler.fail(
                            {ctor: 'BadPayload', _0: result._0}
                        ));
                    }

                    // success
                    return callback(_elm_lang$core$Native_Scheduler.succeed(result._0));
                }; // web3Callback

                var f = eval("web3." + request.func);

                if (request.callType.ctor === "Async") {
                    f.apply(null, request.args.concat( web3Callback ));
                } else if (request.callType.ctor === "Sync") {
                    var syncResult = f.apply(null, request.args);
                /* */
                /* */
                    // web3.reset() returns undefined and needs to be handled accordingly
                    if (syncResult === undefined && request.func === "reset") {
                        return callback(_elm_lang$core$Native_Scheduler.succeed(true));
                    } else if (r === null) {
                        return callback(_elm_lang$core$Native_Scheduler.fail(
                            { ctor: 'Error', _0: config.error.nullResponse }
                        ));
                    } else if (r === undefined) {
                        return callback(_elm_lang$core$Native_Scheduler.fail(
                            { ctor: 'Error', _0: config.error.undefinedResposnse }
                        ));
                    } else {
                        formattedSyncResult = request.expect.responseToResult(formatWeb3Response(syncResult));
                        return callback(_elm_lang$core$Native_Scheduler.succeed(formattedSyncResult._0));
                    }
                /* */
                /* */
                } else {
                    return callback(_elm_lang$core$Native_Scheduler.fail(
                        { ctor: 'Error', _0: "CallType was not defined. This should be impossible." }
                    ));
                };
            } catch (e) {
                console.log(e);
                return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: e.toString() }));
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
                    {ctor: 'Error', _0: "Event sub failed: " + e.toString() }
                ));
            }
        });

        // {
        //  abi:'[]' ,
        //  address: "0xeb8f5983d099b0be3f78367bf5efccb5df9e3487" ,
        //  eventParams: {} ,
        //  filterParams: {} ,
        //  subName: "watchAdd"
        // }
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
        if (r.isBigNumber) { return JSON.stringify(r.toFixed()) }
        config.web3BigNumberFields.forEach( val => {
            if (r[val] !== undefined && r[val].isBigNumber) {
                r[val] = r[val].toFixed();
            }
        });
        return JSON.stringify(r);
    };


    function formatIfBigNum(value) {
        if (value.isBigNumber) {
          return value.toFixed();
        } else {
          return value;
        }
    }


    function formatLog(log) {
        Object.keys(log.args).forEach(function(arg) {
            log.args[arg] = formatIfBigNum(log.args[arg]);
        });
        return log;
    }


    function formatLogsArray(logsArray) {
        logsArray.map(function(log) { formatLog(log) } );
        return logsArray;
    }
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
        watchEvent: watchEvent,
        expectStringResponse: expectStringResponse
    };

}();
