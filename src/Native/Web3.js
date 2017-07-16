// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.
// This file handles the core interaction with web3.js

var _cmditch$elm_web3$Native_Web3 = function() {

    var web3Errors = {
      nullResponse: "Web3 responded with null. Check your parameters. Non-existent address, or unmined block perhaps?",
      undefinedResposnse: "Web3 responded with undefined."
    }

    function request(data) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            try {
                var f = eval("web3." + data.func);
                f.apply(null,
                    data.args.concat( (e, r) => {
                        if (e !== null) {
                            return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: e.toString() }));
                        }

                        if (r === null) {
                          return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: web3Errors.nullResponse }));
                        } else if (r === undefined) {
                          return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: web3Errors.undefinedResposnse }));
                        }

                        var result = data.expect.responseToResult(JSON.stringify(r));
                        return callback(_elm_lang$core$Native_Scheduler.succeed(result._0));
                    }
                ));
            } catch (e) {
                return callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'Error', _0: e.toString() }));
            }
        });
    }

    function expectStringResponse(responseToResult) {
        return {
            responseToResult: responseToResult
        };
    }

    return {
        request: request,
        expectStringResponse: expectStringResponse
    };

}();
