pragma solidity ^0.4.10;

contract LightBox {
  int8 public someNum;
  uint public otherNum;
  address public owner;
  uint[23] public uintArray = [2, 124, 123, 123, 43, 124, 1412423, 123, 657, 42, 4, 123, 124, 756, 123, 657, 123, 1823, 12653, 123, 1293, 12356, 123];

  event Add(address indexed mathematician, int8 sum);
  event Subtract(address indexed professor, uint numberz, int aPrime);
  event UintArray(uint[23] uintArray);

  function LightBox(int8 someNum_) payable {
    someNum = someNum_;
    owner = msg.sender;
  }

  function add_(uint8 a, uint8 b) constant returns (uint8) {
    var sum = a + b;
    return sum;
  }

  function mutateAdd(int8 n) returns (int8) {
    someNum += n;
    UintArray(uintArray);
    Add(msg.sender, someNum);
    return someNum;
  }

  function mutateSubtract(uint n) returns (uint) {
    otherNum += n;
    Subtract(msg.sender, otherNum, 23);
    return otherNum;
  }

  function uintArray() returns (uint[23]) {
    UintArray(uintArray);
    return uintArray;
  }

  function kill () {
    selfdestruct(owner);
  }

}
