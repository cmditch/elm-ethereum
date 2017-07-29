Fitler/Event Guide

// Returns Log. Beware - lots of repeat incoming messages
latestFilter = web3.eth.filter()
latestFilter.watch(callback) // -> Log

// Returns block hash once it's been mined
latestFilter = web3.eth.filter('latest')
latestFilter.watch(callback) // -> BlockHash


// Returns txHashes as they hit the pending block
pendingFilter = web3.eth.filter('pending')
pendingFilter.watch(callback) // -> TxId


optionsFilter = web3.eth.filter(
  {fromBlock: 'latest', toBlock: 'latest', address: '0x1231..', topics: ['0x123', null, '0x31']}
)



contractAddress = '0xE94327D07Fc17907b4DB788E5aDf2ed424adDff6'
abi = [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"initialized","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_holder","type":"address"}],"name":"migrateBalance","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"targetSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"unpause","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_holders","type":"address[]"}],"name":"migrateBalances","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"paused","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"pause","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"legacyRepContract","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"inputs":[{"name":"_legacyRepContract","type":"address"},{"name":"_amountUsedToFreeze","type":"uint256"},{"name":"_accountToSendFrozenRepTo","type":"address"}],"payable":false,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"holder","type":"address"},{"indexed":false,"name":"amount","type":"uint256"}],"name":"Migrated","type":"event"},{"anonymous":false,"inputs":[],"name":"Pause","type":"event"},{"anonymous":false,"inputs":[],"name":"Unpause","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]

rep = web3.eth.contract(abi).at(contractAddress)

holder = '0x7e614ec62cfd5761f20a9c5a2fe2bc0ac7431918'

// filter = rep.Migrated({holder: '0x907fb2f0b0e60dba7613a82be6982b8f9ebcedb7'})

filter = rep.Migrated({}, {fromBlock: 4086927}) // 63 logs returned

function formatIfBigNum(value) {
    if (value.isBigNumber) {
      return value.toFixed();
    } else {
      return value;
    }
}

function formatLog(log) {
    Object.keys(log.args).forEach(function(arg) {
      log.args[arg] = formatIfBigNum(log.args[arg]);
    });
    return log;
}

function formatLogsArray(logsArray) {
    logsArray.map(function(log) { formatLog(log) } );
    return logsArray;
}



var b;
filter.get((e,r) => b = r )

setTimeout( function() {
    b = b.concat(b).concat(b).concat(b)
    b = b.concat(b).concat(b).concat(b)
    console.log(b.length);
    formatLogsArray(b);
}, 1000)



formatAndStringify(b); // It takes around 650ms to format 1,000,000 records



// Looking into how easy it would be to convert BigNumber to BigInt.
// This might be fruitless, as we're already using the Expect functions for decoding our Web3.toTask responses
// And the compiler won't let you accept anything other than JSON/JS values, so this would be unusable with ports/subs.

// BigNumber is max 14 in length.
{c :
  [ 0 = 1234
    1 = 12341234123412
    2 = 34214312531235
    3 = 12351235123512
    4 = 35123521351298
    5 = 67967896789635
  ]
}

"12341234123412341234214312531235123512351235123512352135129867967896789635"

Just Pos
0 = Magnitude List(11)
    0 = 6789635
    1 = 6796789
    2 = 1351298
    3 = 3512352
    4 = 5123512
    5 = 1235123
    6 = 2531235
    7 = 3421431
    8 = 4123412
    9 = 1234123
    10 = 1234
