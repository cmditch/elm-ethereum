pragma solidity ^0.4.10;

contract LightBox {
  int8 public someNum;
  uint public otherNum;
  address public owner;

  event Add(address indexed mathematician, int8 sum);
  event Subtract(address indexed professor, uint numberz, int aPrime);

  function LightBox(int8 someNum_) payable {
    someNum = someNum_;
    owner = msg.sender;
  }

  function add(uint8 a, uint8 b) constant returns (uint8) {
    var sum = a + b;
    return sum;
  }

  function mutateAdd(int8 n) returns (int8) {
    someNum += n;
    Add(msg.sender, someNum);
    return someNum;
  }

  function mutateSubtract(uint n) returns (uint) {
    otherNum += n;
    Subtract(msg.sender, otherNum, 23);
    return otherNum;
  }

  function kill () {
    selfdestruct(owner);
  }

}
