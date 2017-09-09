// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.
// This file handles the core interaction with web3.js

var _cmditch$elm_web3$Native_Web3 = function() {

    var config =
    {
        web3BigNumberFields: ["totalDifficulty", "difficulty", "value", "gasPrice"],
        error:
        {
            nullResponse: "Web3 responded with null. Unlock wallet if using MetaMask. Otherwise, check your parameters. Non-existent address, or unmined block perhaps?",
            undefinedResposnse: "Web3 responded with undefined.",
            deniedTransaction: "MetaMask Tx Signature: User denied transaction signature.",
            unknown: "Unknwown till further testing is performed."
        }
    };

    // shorthand for native APIs
    var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
    var succeed = _elm_lang$core$Native_Scheduler.succeed;
    var fail = _elm_lang$core$Native_Scheduler.fail;
    var rawSpawn = _elm_lang$core$Native_Scheduler.rawSpawn;
    var unit = {ctor: '_Tuple0'};

/*
    TODO  Use Web3 Error constructor functions instead of raw objects.

    TODO  Remove the bulk of the console.log's once we go Beta -> 1.0
          We'll have to decide which ones to leave in for 1.0, if any at all.

    TODO  Perhaps return a tuple of errors, where: (simpleDescription, fullConsoleOutput)?
        Probably not, let's just work on hammering out all error cases
        and replying with meaningful messages in a elm-ish fashion.
*/

    function toTask(request) {
        console.log("toTask: ", request);
        return nativeBinding(function(callback) {
            try
            {
                function web3Callback(e,r)
                {
                    var result = handleWeb3Response({
                        error: e,
                        response: r,
                        decoder: request.expect.responseToResult,
                        // funcName for debugging
                        funcName: request.method
                    });

                    console.log(request.method + " ASYNC result: ", result);

                    switch (result.ctor)
                    {
                        case "Ok": return callback(succeed(result._0));
                        case "Err": return callback(fail({ ctor: 'Error', _0: result._0 }));
                    };
                };

                var func = eval("web3." + request.method);

                if (request.callType.ctor === "Async")
                {
                    func.apply(null, request.params.concat( web3Callback ));
                }
                else if (request.callType.ctor === "Sync")
                {
                    var web3Response = func.apply(null, request.params);
                    var result = handleWeb3Response({
                        error: null,
                        response: web3Response,
                        decoder: request.expect.responseToResult,
                        // funcName for debugging
                        funcName: request.method
                    });

                    console.log(request.method + " SYNC result: ", result);

                    switch (result.ctor)
                    {
                        case "Ok": return callback(succeed(result._0));
                        case "Err": return callback(fail({ ctor: 'Error', _0: result._0 }));
                    };
                };
            }
            catch (err)
            {
                console.log("Try/Catch error on toTask", err);
                return callback(fail({
                    ctor: 'Error', _0: "Tried and caught: " + err.toString()
                }));
            }
        });
    };


    function setOrGet(request) {
        console.log("setOrGet: ", request);
        return nativeBinding(function(callback)
        {
            try
            {   // TODO Dangerous without Err catching on decoding result...
                var response;

                switch (request.callType.ctor) {
                    case "Setter":
                        response = eval("web3." + request.method + " = '" + request.params + "'");
                    case "Getter":
                        response = eval("web3." + request.method);
                }

                if (response !== undefined)
                {
                    return callback(succeed(
                        request.expect.responseToResult(JSON.stringify(response))._0
                    ));
                }
                else
                {
                    return callback(fail({
                        ctor: 'Error', _0: request.method + " setter failed - undefined response."
                    }));
                }
                console.log("Getter decode: ", result)
            }
            catch(err)
            {
                console.log("Try/Catch error on setter", err);
                return callback(fail({
                    ctor: 'Error', _0: "Web3 setter failed: " + err.toString()
                }));
            }

        });
    }

    function contract(evalString, request) {
        return nativeBinding(function(callback)
        {
            try
            {
                function web3Callback(e,r)
                {
                    var result = handleWeb3Response({
                        error: e,
                        response: r,
                        decoder: request.expect.responseToResult,
                        // funcName for debugging
                        funcName: request.method
                    });
                    switch (result.ctor)
                    {
                        case "Ok": return callback(succeed(result._0));
                        case "Err": return callback(fail({ ctor: 'Error', _0: result._0 }));
                    };
                };

                /* start magic */
                var response = eval(evalString);
                /* end magic */

                if (request.callType.ctor === "Sync")
                {
                  var result = request.expect.responseToResult(JSON.stringify(response));
                  switch (result.ctor)
                  {
                      case "Ok": return callback(succeed(result._0));
                      case "Err": return callback(fail({ ctor: 'Error', _0: result._0 }));
                  };
                }
            }
            catch(err)
            {
                return callback(fail({
                    ctor: 'Error', _0: "Contract " + request.method + " failed - " + err.toString()
                }));
            }
        });
    };


    function watchEvent(request, onMessage)
    {
        console.log(request)
        return nativeBinding(function(callback)
        {
            var eventFilter;
            try
		    {
                request.isContractEvent === true
                ? eventFilter = eval("web3." + request.method).apply(null, request.params)
                : eventFilter = eval("web3." + request.method)
            }
            catch(err)
            {
                return callback(fail({
                    ctor: 'Error',
                    _0: err.toString()
                }));
                console.log("Event watch error: ", err);
            }

            eventFilter.watch(function(e,r) {
                if (e) { return console.log(e); }

                request.isContractEvent === true
                ? rawSpawn(onMessage(JSON.stringify(formatLog(r))))
                : rawSpawn(onMessage(JSON.stringify(r)))

                console.log(r);
            });
            console.log("Event watched: ", eventFilter);
            return callback(succeed(eventFilter));
        });
    }


    function stopWatchingEvent(eventFilter)
    {
        return nativeBinding(function(callback)
        {
            try
            {
                console.log("Event watching stopped: ", eventFilter);
                eventFilter.stopWatching();
                return callback(succeed(unit));
            }
            catch (err)
            {
                console.log(err);
                return callback(fail({
                    ctor: 'Error',
                    _0: err.toString()
                }));
            }
        });
    }


    function getEvent(request)
    {
        return nativeBinding(function(callback)
        {
            try
            {
                function web3Callback(e,r)
                {
                    var result = handleWeb3Response({
                        error: e,
                        response: formatLogsArray(r),
                        wasGetEvent: true,
                        decoder: request.expect.responseToResult
                    });

                    console.log("getEvent result: ", result)

                    switch (result.ctor)
                    {
                        case "Ok": return callback(succeed(result._0));
                        case "Err": return callback(fail({ ctor: 'Error', _0: result._0 }));
                    };
                };

                var eventParams = request.params.map(function(arg) {
                    return JSON.stringify(arg)
                });

                eval(
                    "web3."
                    + request.method
                    + "("
                    + eventParams.join(",")
                    + ")"
                ).get(web3Callback);
            }
            catch(err)
            {
                console.log(err);
                return callback(fail({
                    ctor: 'Error',
                    _0: err.toString()
                }));
            }
        });
    }


    //  TODO Handle this in the Effects Manager
    function reset(keepIsSyncing)
    {
        console.log("web3.reset called");
        return nativeBinding(function(callback)
        {
            try
            {
                eval("web3.reset(" + keepIsSyncing.toString() + ")")
                console.log(eventRegistry);
                return callback( succeed(unit) );
            }
            catch (err)
            {
                console.log("Try/Catch error on web3.reset", err);
                return callback( fail({ ctor: 'Error', _0: "Event reset failed - " + err.toString() }) );
            }
        });
    };


    function expectStringResponse(responseToResult) {
        return {
            responseToResult: responseToResult
        };
    };


    function handleWeb3Response(r)
    {
        console.log("handleWeb3Response: ")
        if (r.error !== null)
        {
            console.log("Web3 response error: ",r);
            return {ctor: "Err", _0: r.error.message.split("\n")[0] }
        }
        else if (r.wasGetEvent)
        {
            return r.decoder( JSON.stringify(r.response) )
        }
        else if (r.decoder !== undefined)
        {
            console.log("Web3 was async w/ decoder: ", r);
            // decoder returns a Result
            return r.decoder( JSON.stringify(r.response) );
        }
        else
        {
            console.log("Web3 was sync: ", r);
            return { ctor: 'Ok', _0: r.response }
        }
    };




    return {
        toTask: toTask,
        setOrGet: setOrGet,
        contract: F2(contract),
        watchEvent: F2(watchEvent),
        stopWatchingEvent: stopWatchingEvent,
        getEvent: getEvent,
        reset: reset, //TODO implement into Effect Manager and clear Web3Event Dict
        expectStringResponse: expectStringResponse
    };

}();
