// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.
// This file handles the core interaction with web3.js

var _cmditch$elm_web3$Native_Web3 = function() {

    function request(data) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            console.log(data);

            var f = eval("web3." + data.func);
            f.apply(null,
                data.args.concat((e, r) => {
                    if (e) {
                        return callback(_elm_lang$core$Native_Scheduler.fail(e.toString()));
                    }

                    return callback(_elm_lang$core$Native_Scheduler.succeed(JSON.stringify(r)));
                }
            ));
        });
    }

    return {
        request: request
    };

}();
