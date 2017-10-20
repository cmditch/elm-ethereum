var _cmditch$elm_web3$Native_Web3 = function() {

    var web3Error = function(e) { return {ctor: "Error", _0: e} };
    var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
    var succeed = _elm_lang$core$Native_Scheduler.succeed;
    var fail = _elm_lang$core$Native_Scheduler.fail;
    var rawSpawn = _elm_lang$core$Native_Scheduler.rawSpawn;
    var unit = {ctor: '_Tuple0'};


    function toTask(evalString, request) {
        return nativeBinding(function(callback)
        {
            try
            {
                var callType = request.callType.ctor;
                function elmCallback(r)
                {
                    var result = request.expect.responseToResult( JSON.stringify(r) );
                    switch (result.ctor)
                    {
                        case "Ok": return callback(succeed( result._0 ));
                        case "Err": return callback(fail( web3Error(result._0) ));
                    };
                };

                function web3Callback(e,r)
                {
                    if (e) { return callback(fail( web3Error(e.message) ))};
                    elmCallback(r);
                };

                var response = eval(evalString);
                if (callType === "Sync" || callType === "Getter")
                {
                    elmCallback(response)
                }
                else if (callType === "CustomSync")
                {
                    elmCallback( eval(request.callType._0) );
                }
            }
            catch(e)
            {
                return callback(fail( web3Error(e.message) ));
            }
        });
    };


    function createContractEventEmitter(abi, address, eventId) {
        return nativeBinding(function(callback)
        {
            try
            {
                callback(succeed(
                    eval("new web3.eth.Contract(JSON.parse(abi), address).events[eventId]()")
                ));
            }
            catch(e)
            {
                console.log(e);
            }
        });
    };


    function createEventEmitter(subType, options) {
        return nativeBinding(function(callback)
        {
            try
            {   // Only "logs" subscription type needs options object
                var params = options ? "(subType, options)" : "(subType)";
                var emitter = eval("web3.eth.subscribe" + params);
                callback(succeed(emitter));

            }
            catch(e)
            {
                console.log(e);
            }
        });
    };


    function eventSubscribe(eventEmitter, onMessage) {
        try
        {
            eventEmitter.callback = function(error, log) {
                return rawSpawn(onMessage(JSON.stringify(log)));
            };
        }
        catch(e)
        {
            console.log(e);
        }
    };


    function eventUnsubscribe(eventEmitter) {
        try
        {
            eventEmitter.unsubscribe();
        }
        catch(e)
        {
            console.log(e);
        }
    };

    function clearAllSubscriptions(bool) {
        try
        {   // TODO Web3 function doesn't work???
            eval("web3.eth.clearSubscriptions(bool)");
        }
        catch(e)
        {
            console.log(e);
        }
    };

    function expectStringResponse(responseToResult) {
        return {
            responseToResult: responseToResult
        };
    };


    return {
        toTask: F2(toTask),
        createContractEventEmitter: F3(createContractEventEmitter),
        createEventEmitter: F2(createEventEmitter),
        eventSubscribe: F2(eventSubscribe),
        eventUnsubscribe: eventUnsubscribe,
        clearAllSubscriptions: clearAllSubscriptions,
        expectStringResponse: expectStringResponse
    };

}();
