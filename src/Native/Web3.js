// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.
// This file handles the core interaction with web3.js

var _cmditch$elm_web3$Native_Web3 = function() {

    var config =
    {
        web3BigNumberFields: ["totalDifficulty", "difficulty", "value", "gasPrice"],
        error:
        {
            nullResponse: "Web3 responded with null. Check your parameters. Non-existent address, or unmined block perhaps?",
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
        console.log("To task: ", request);
        return nativeBinding(function(callback) {
            try
            {
                function web3Callback(e,r)
                {
                    var result = handleWeb3Response({
                        error: e,
                        response: r,
                        decoder: request.expect.responseToResult
                    });

                    console.log("Async result: ", result)

                    switch (result.ctor)
                    {
                        case "Ok": return callback(succeed(result._0));
                        case "Err": return callback(fail({ ctor: 'Error', _0: result._0 }));
                    };
                };

                var func = eval("web3." + request.func);

                if (request.callType.ctor === "Async")
                {
                    func.apply(null, request.args.concat( web3Callback ));
                }
                else if (request.callType.ctor === "Sync")
                {
                    var web3Response = func.apply(null, request.args);
                    var result = handleWeb3Response({
                        error: null,
                        response: r,
                        decoder: undefined
                    });

                    console.log("Sync result: ", result);

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
                        response = eval("web3." + request.func + " = '" + request.args + "'");
                    case "Getter":
                        response = eval("web3." + request.func);
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
                        ctor: 'Error', _0: request.func + " setter failed - undefined response."
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

    function contractGetData(request) {
        console.log("contractGetData: ", request);
        return nativeBinding(function(callback)
        {
            try
            {
                var response =
                    eval("web3.eth.contract("
                        + request.abi
                        + ").getData("
                        + request.constructorParams.join()
                        + ", {data: '"
                        + request.data
                        + "'})"
                    )
                console.log(response);
                return callback(succeed({ ctor: "Bytes", _0: response }));
            }
            catch(err)
            {
                console.log("Try/Catch error on contractGetData", err);
                return callback(fail({
                    ctor: 'Error', _0: "Contract.getData failed - " + err.toString()
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
                ? eventFilter = eval("web3." + request.func).apply(null, request.args)
                : eventFilter = eval("web3." + request.func)
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

                var eventParams = request.args.map(function(arg) {
                    return JSON.stringify(arg)
                });

                eval(
                    "web3."
                    + request.func
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


/*
//  TODO Need to account for arrays of BigInts.
//  Run on all web3 repsonses.
//  (error, response, Expect/Decoder function) -> Result Err Ok
*/
    function handleWeb3Response(r)
    {
        console.log("handleWeb3Response: ")
        if (r.error !== null)
        {
            console.log("Web3 response error: ",r);
            return {ctor: "Err", _0: r.error.message.split("\n")[0] }
        }
        else if (r.response === null)
        {
            console.log("Web3 response was null: ", r);
            return {ctor: "Err", _0: config.error.nullResponse }
        }
        else if (r.response === undefined)
        {
            console.log("Web3 response was undefined: ", r);
            return { ctor: "Err", _0: config.error.undefinedResposnse }
        }
        else if (r.wasGetEvent)
        {
            return r.decoder( JSON.stringify(r.response) )
        }
        else if (r.decoder !== undefined)
        {
            console.log("Web3 was async w/ decoder: ", r);
            // decoder returns a Result
            return r.decoder( formatWeb3Response(r.response) )
        }
        else
        {
            console.log("Web3 was sync: ", r);
            return { ctor: 'Ok', _0: r.response }
        }
    };


/*
//  Run on all async web3 repsonses.
//  Turns BigNumber into full strings.
*/
    function formatWeb3Response(r)
    {
        if (r.isBigNumber) { return JSON.stringify(r.toFixed()) }

        config.web3BigNumberFields.forEach(function(val)
        {
            if (r[val] !== undefined && r[val].isBigNumber)
            {
                    r[val] = r[val].toFixed()
            }
        });

        return JSON.stringify(r);
    };


/*
//  Run on all web3 event repsonses (logs).
//  Turns BigNumber into full strings.
*/
    function formatLogsArray(logsArray)
    {
        logsArray.map(function(log) { formatLog(log) } );
        return logsArray;
    }


    function formatLog(log)
    {
        Object.keys(log.args).forEach(function(arg)
        {
            log.args[arg] = formatIfBigNum(log.args[arg]);
        });
        return log;
    }


    function formatIfBigNum(value)
    {
        if (value.isBigNumber)
        {
            return value.toFixed();
        }
        else if (Array.isArray(value))
        {
            return value.map(function(val)
            {
                return formatIfBigNum(val);
            });
        }
        else
        {
            return value;
        }
    }


    return {
        toTask: toTask,
        setOrGet: setOrGet,
        contractGetData: contractGetData,
        watchEvent: F2(watchEvent),
        stopWatchingEvent: stopWatchingEvent,
        getEvent: getEvent,
        reset: reset, //TODO implement into Effect Manager and clear Web3Event Dict
        expectStringResponse: expectStringResponse
    };

}();
