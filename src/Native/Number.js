//Native.Scheduler //

var _cmditch$elm_web3$Native_Number = function() {

function getNumber(number)
{
	return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
			return callback(_elm_lang$core$Native_Scheduler.succeed(number + 1));
	});
}

return {
	getNumber: getNumber
};

}();
