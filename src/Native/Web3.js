// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.

var _cmditch$elm_web3$Native_Web3 = function() {

    var web3Error = function(e) { return {ctor: "Error", _0: e} };
    var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
    var succeed = _elm_lang$core$Native_Scheduler.succeed;
    var fail = _elm_lang$core$Native_Scheduler.fail;
    var rawSpawn = _elm_lang$core$Native_Scheduler.rawSpawn;
    var unit = {ctor: '_Tuple0'};


    function toTask(evalString, request) {
        console.log(evalString, request);
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
                console.log(e);
                return callback(fail( web3Error(e.message) ));
            }
        });
    };


    function expectStringResponse(responseToResult) {
        return {
            responseToResult: responseToResult
        };
    };


    return {
        toTask: F2(toTask),
        expectStringResponse: expectStringResponse
    };

}();
