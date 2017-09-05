pragma solidity ^0.4.10;

contract TestContract {
  int public mutableInt;
  string public constructorString;
  uint public otherNum;
  address public owner;
  uint[23] public uintArray = [123123123123123123123123, 124, 123, 12312312312123123123123123, 43, 123123123123123123123123, 1412423, 123, 657, 42, 4, 123, 123122323123123123123123123, 756, 123, 657, 123123123123123123123123, 1823, 12653, 123, 1293, 12356, 123];

  event Add(address indexed mathematician, int intLog);
  event Subtract(address indexed professor, uint numberz, int aPrime);
  event UintArray(uint[23] uintArrayLog);

  function TestContract(int constructorInt_, string constructorString_) payable {
    mutableInt = constructorInt_;
    constructorString = constructorString_;
    owner = msg.sender;
  }

  function returnsOneNamed(uint a, uint b) constant returns (uint someNumber) {
    return a + b;
  }

  function returnsOneUnnamed(uint a, uint b) constant returns (uint) {
    return a + b;
  }

  function returnsTwoNamed(uint a, uint b) constant returns (uint someUint, string someString ) {
    return (a + b, "This is a test");
  }

  function returnsTwoUnnamed(uint a, uint b) constant returns (uint, string) {
    return (a + b, "This is a test");
  }

  function kill () {
    selfdestruct(owner);
  }

}
