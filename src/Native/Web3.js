// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.
// This file handles the core interaction with web3.js

var _cmditch$elm_web3$Native_Web3 = function() {

    var web3Errors = {
      nullResponse: "Web3 responded with null. Check your parameters. Non-existent address, or unmined block perhaps?",
      undefinedResposnse: "Web3 responded with undefined."
    };

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
                                { ctor: 'Error', _0: web3Errors.nullResponse }
                            ));
                        } else if (r === undefined) {
                            return callback(_elm_lang$core$Native_Scheduler.fail(
                                { ctor: 'Error', _0: web3Errors.undefinedResposnse }
                            ));
                        }

                        // Decode the payload using Elm function passed to Expect
                        var result = request.expect.responseToResult(JSON.stringify(r));
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
                return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: e.toString() }));
            }
        });
    };

    function expectStringResponse(responseToResult) {
        return {
            responseToResult: responseToResult
        };
    };


    return {
        toTask: toTask,
        expectStringResponse: expectStringResponse
    };

}();
