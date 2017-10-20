// elm-web3 native module
// Warning: Here be dragons. Modify this file carefully.

var _cmditch$elm_web3$Native_Subscribe = function() {

    var nativeBinding = _elm_lang$core$Native_Scheduler.nativeBinding;
    var succeed = _elm_lang$core$Native_Scheduler.succeed;
    var fail = _elm_lang$core$Native_Scheduler.fail;
    var rawSpawn = _elm_lang$core$Native_Scheduler.rawSpawn;


    function createEventEmitter(subType, options) {
        return nativeBinding(function(callback)
        {
            try
            {   // Will only pass options for "logs"
                var params = options ? "(subType, options)" : "(subType)";
                callback(succeed(eval("web3.eth.subscribe" + params)));
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


    return {
        createEventEmitter: F3(createEventEmitter),
        eventSubscribe: F2(eventSubscribe),
        eventUnsubscribe: eventUnsubscribe,
    };

}();
