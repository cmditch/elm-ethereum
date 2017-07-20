pragma solidity ^0.4.11;

contract TestBox {
  string public name = 'Santa';
  bytes public location = 'North Pole';
  uint public age = 623;
  uint public flipCount = 0;
  bool public jolly = true;
  address public giftSack = 0x15ecFc141e68Ff6B3BacF0a1aC089329f9f90897;
  address public owner;

  mapping (address => bool) public theList;

  event Add (int sum);
  event Subtract (int difference);
  event JollyFlipped (bool jollyWasFlipped, bool jollyState, uint flipCount);
  event IHazNiceness (bool nice);

  function TestBox () {
    owner = msg.sender;
  }

  function add (int a, int b) constant returns (int) {
    var sum = a + b;
    Add(sum);
    return sum;
  }

  function subtract (int a, int b) constant returns (int) {
    var diff = a - b;
    Subtract(diff);
    return diff;
  }

  function flipJolly () returns (bool) {
    if (msg.sender == owner) {
      jolly = !jolly;
      flipCount += 1;
      JollyFlipped(true, jolly, flipCount);
      return jolly;
    } else {
      JollyFlipped(false, jolly, flipCount);
      return jolly;
    }
  }

  function writeToTheList () returns (bool) {
    var amINice = jolly;
    theList[msg.sender] = amINice;
    IHazNiceness(amINice);
    return amINice;
  }

  function queryList(address addr) constant returns (bool) {
    var amINice = theList[addr];
    IHazNiceness(amINice);
    return amINice;
  }

}
