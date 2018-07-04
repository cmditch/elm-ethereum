pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;


contract ComplexStorage {
    uint public uintVal = 123;
    int public intVal = -128;
    bool public boolVal = true;
    int224 public int224Val = -999999999999999999999999999999999999999999999999999999999999999;
    bool[2] public boolVectorVal = [true, false];
    int[] public intListVal = [1, 2, 3, int224Val, -10, 1, 2, 34];
    string public stringVal = "wtf mate";
    bytes16 public bytes16Val = "1234567890123456";
    bytes2 public bytes2Val = 0xffff;
    bytes2 a = 0x1234;
    bytes2 b = 0x5678;
    bytes2[4] public bytes2Vector = [a, b, bytes2Val];
    bytes2[4][] public bytes2VectorListVal = [bytes2Vector, bytes2Vector, bytes2Vector];
    string[][] public dynArrayOfDynVal = [["testingthisshouldbequiteabitlongerthan1word"], ["shorter"], ["s"]];

    event ValsSet(uint a, int b, bool c, int224 d, bool[2] e, int[] f, string g, bytes16 h, bytes2[4][] i);

    function setValues(uint _uintVal, int _intVal, bool _boolVal, int224 _int224Val, bool[2] _boolVectorVal, int[] _intListVal, string _stringVal, bytes16 _bytes16Val, bytes2[4][] _bytes2VectorListVal) public {
         uintVal =           _uintVal;
         intVal =            _intVal;
         boolVal =           _boolVal;
         int224Val =         _int224Val;
         boolVectorVal =     _boolVectorVal;
         intListVal =        _intListVal;
         stringVal   =       _stringVal;
         bytes16Val   =      _bytes16Val;
         bytes2VectorListVal = _bytes2VectorListVal;

         emit ValsSet(_uintVal, _intVal, _boolVal, _int224Val, _boolVectorVal, _intListVal, _stringVal, _bytes16Val, _bytes2VectorListVal);
    }

    function getVals () constant public returns (uint, int, bool, int224, bool[2], int[], string, bytes16, bytes2[4][], string[][]) {
      return (uintVal, intVal, boolVal, int224Val, boolVectorVal, intListVal, stringVal, bytes16Val, bytes2VectorListVal, dynArrayOfDynVal);
    }

}

