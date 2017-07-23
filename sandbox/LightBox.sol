pragma solidity ^0.4.13;

contract LightBox {
  int8 public someNum;

  event Add (address indexed mathematician, uint8 sum);

  function LightBox (int8 someNum_) payable {
    someNum = someNum_;
  }

  function add (uint8 a, uint8 b) constant returns (uint8) {
    var sum = a + b;
    Add(msg.sender, sum);
    return sum;
  }

}
