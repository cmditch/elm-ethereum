// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.
// This file handles the core interaction with web3.js

var _cmditch$elm_web3$Native_Web3 = function() {

    const config = {
        web3BigNumberFields: ["totalDifficulty", "difficulty", "value", "gasPrice"],
        error: {
            // TODO should timeout be it's own error type? Probably not, since only deployContract can timeout currently.
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
                var web3Callback = function(e,r) {
                    // Args passed from elm are always appended with an Error-First style callback,
                    // in order to satisfy web3's aysnchronus by design nature.

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
                    var result = request.expect.responseToResult( JSON.stringify(r) );
                    console.log(result);
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
                    syncResult = request.expect.responseToResult( JSON.stringify(syncResult) );
                    return callback(_elm_lang$core$Native_Scheduler.succeed(syncResult._0));
                } else {
                    return callback(_elm_lang$core$Native_Scheduler.fail(
                      { ctor: 'Error', _0: "Synchronus call failed." }
                    ));
                };
            } catch (e) {
                console.log(e);
                return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: e.toString() }));
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
        expectStringResponse: expectStringResponse
    };

}();
