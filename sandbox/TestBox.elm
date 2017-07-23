module TestBox exposing (..)

import Web3 exposing (Error)
import Web3.Eth.Types exposing (Address, Abi, TxParams, TxData, NewContract)
import Web3.Eth.Contract
import Task exposing (Task)
import BigInt exposing (BigInt)


type alias Constructor =
    { age_ : BigInt }


abi : Abi
abi =
    """[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"writeToTheList","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"age","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"flipCount","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"giftSack","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"location","outputs":[{"name":"","type":"bytes"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"theList","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"addr","type":"address"}],"name":"queryList","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"a","type":"int256"},{"name":"b","type":"int256"}],"name":"add","outputs":[{"name":"","type":"int256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"a","type":"int256"},{"name":"b","type":"int256"}],"name":"subtract","outputs":[{"name":"","type":"int256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"jolly","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"flipJolly","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"inputs":[{"name":"age_","type":"uint256"}],"payable":false,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"name":"sum","type":"int256"}],"name":"Add","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"difference","type":"int256"}],"name":"Subtract","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"jollyWasFlipped","type":"bool"},{"indexed":false,"name":"jollyState","type":"bool"},{"indexed":false,"name":"flipCount","type":"uint256"}],"name":"JollyFlipped","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"nice","type":"bool"}],"name":"IHazNiceness","type":"event"}]"""


data : TxData
data =
    """0x60606040526040805190810160405280600581526020017f53616e74610000000000000000000000000000000000000000000000000000008152506000908051906020019061004f929190610188565b506040805190810160405280600a81526020017f4e6f72746820506f6c65000000000000000000000000000000000000000000008152506001908051906020019061009b929190610208565b5060006003556001600460006101000a81548160ff0219169083151502179055507315ecfc141e68ff6b3bacf0a1ac089329f9f90897600460016101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550341561011c57600080fd5b604051602080610c9b833981016040528080519060200190919050505b33600560006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550806002819055505b506102ad565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106101c957805160ff19168380011785556101f7565b828001600101855582156101f7579182015b828111156101f65782518255916020019190600101906101db565b5b5090506102049190610288565b5090565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061024957805160ff1916838001178555610277565b82800160010185558215610277579182015b8281111561027657825182559160200191906001019061025b565b5b5090506102849190610288565b5090565b6102aa91905b808211156102a657600081600090555060010161028e565b5090565b90565b6109df806102bc6000396000f300606060405236156100c3576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806306fdde03146100c8578063077b524e14610157578063262a9dff146101845780634dc8c475146101ad5780634fb4adf4146101d6578063516f279e1461022b5780635c0b51fb146102ba5780638da5cb5b1461030b5780638f7ac60d14610360578063a5f3c23b146103b1578063b93ea812146103f1578063d11520f014610431578063f93b45301461045e575b600080fd5b34156100d357600080fd5b6100db61048b565b6040518080602001828103825283818151815260200191508051906020019080838360005b8381101561011c5780820151818401525b602081019050610100565b50505050905090810190601f1680156101495780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b341561016257600080fd5b61016a610529565b604051808215151515815260200191505060405180910390f35b341561018f57600080fd5b6101976105d8565b6040518082815260200191505060405180910390f35b34156101b857600080fd5b6101c06105de565b6040518082815260200191505060405180910390f35b34156101e157600080fd5b6101e96105e4565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b341561023657600080fd5b61023e61060a565b6040518080602001828103825283818151815260200191508051906020019080838360005b8381101561027f5780820151818401525b602081019050610263565b50505050905090810190601f1680156102ac5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34156102c557600080fd5b6102f1600480803573ffffffffffffffffffffffffffffffffffffffff169060200190919050506106a8565b604051808215151515815260200191505060405180910390f35b341561031657600080fd5b61031e6106c8565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b341561036b57600080fd5b610397600480803573ffffffffffffffffffffffffffffffffffffffff169060200190919050506106ee565b604051808215151515815260200191505060405180910390f35b34156103bc57600080fd5b6103db6004808035906020019091908035906020019091905050610785565b6040518082815260200191505060405180910390f35b34156103fc57600080fd5b61041b60048080359060200190919080359060200190919050506107cf565b6040518082815260200191505060405180910390f35b341561043c57600080fd5b610444610819565b604051808215151515815260200191505060405180910390f35b341561046957600080fd5b61047161082c565b604051808215151515815260200191505060405180910390f35b60008054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156105215780601f106104f657610100808354040283529160200191610521565b820191906000526020600020905b81548152906001019060200180831161050457829003601f168201915b505050505081565b600080600460009054906101000a900460ff16905080600660003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055507f5b9d77aa14b895f8a99b6d10087d9af5068db8546d105c7b9e54388b3b8211da81604051808215151515815260200191505060405180910390a18091505b5090565b60025481565b60035481565b600460019054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60018054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156106a05780601f10610675576101008083540402835291602001916106a0565b820191906000526020600020905b81548152906001019060200180831161068357829003601f168201915b505050505081565b60066020528060005260406000206000915054906101000a900460ff1681565b600560009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600080600660008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff1690507f5b9d77aa14b895f8a99b6d10087d9af5068db8546d105c7b9e54388b3b8211da81604051808215151515815260200191505060405180910390a18091505b50919050565b60008082840190507fff108fcbf08e0878885eb45335024c83f18d9515a30bd862c4d6898a0a0e93d5816040518082815260200191505060405180910390a18091505b5092915050565b60008082840390507f50afb918f2c657fd102e2a74769c6bef271b3f01141650ec8b404908387f1a5b816040518082815260200191505060405180910390a18091505b5092915050565b600460009054906101000a900460ff1681565b6000600560009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16141561093757600460009054906101000a900460ff1615600460006101000a81548160ff02191690831515021790555060016003600082825401925050819055507ff9336f549c963356c59ca7250a3a59eaeea06b535a6e32b8c40fac79302e09676001600460009054906101000a900460ff16600354604051808415151515815260200183151515158152602001828152602001935050505060405180910390a1600460009054906101000a900460ff1690506109b0565b7ff9336f549c963356c59ca7250a3a59eaeea06b535a6e32b8c40fac79302e09676000600460009054906101000a900460ff16600354604051808415151515815260200183151515158152602001828152602001935050505060405180910390a1600460009054906101000a900460ff1690506109b0565b5b905600a165627a7a72305820a479efbd00739cb508379b6ea45b814c0354b9972b11c2e65d3a923ee092d4560029"""



-- new : TxParams -> Task Error ( Maybe Address, TxId )
-- metamask gas Price = 862198
-- testrpc gas price == 876408
--
-- Collisions will be possible between constructor names in someones solidity contract and values used elm
-- Mitigation needed during code generation. Last 6 chars of the abi's hash appended to constructor param names?


new : Address -> Maybe BigInt -> Constructor -> Task Error NewContract
new address value { age_ } =
    let
        value_ =
            Maybe.map BigInt.toString value
                |> Maybe.withDefault "0"

        ctorArg1 =
            BigInt.toString age_

        deployFunc =
            "eth.contract("
                ++ abi
                ++ ").new"
                ++ "("
                ++ ctorArg1
                ++ ", {from: "
                ++ "web3.eth.accounts[0]"
                ++ ", value: '"
                ++ value_
                ++ "', gas: "
                ++ "'2000000'"
                ++ ", data: '"
                ++ data
                ++ "'}, metaMaskCallBack )"
    in
        Web3.Eth.Contract.deployContract deployFunc
