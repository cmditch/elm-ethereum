pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;


contract ComplexStorage {
    uint public uintVal = 123;
    int public intVal = -128;
    bool public boolVal = true;
    int224 public int224Val = -999999999999999999999999999999999999999999999999999999999999999;
    bool[2] public boolVectorVal = [true, false];
    int[] public intListVal = [1, 2, 3, int224Val, -10, 1, 2, 34];
    uint[] public emptyArray;
    string public stringVal = "wtf mate";
    bytes16 public bytes16Val = "1234567890123456";
    bytes2 public bytes2Val = 0xffff;
    bytes2 a = 0x1234;
    bytes2 b = 0x5678;
    bytes2[4] public bytes2Vector = [a, b, bytes2Val];
    bytes2[4][] public bytes2VectorListVal = [bytes2Vector, bytes2Vector, bytes2Vector];
    string[]   public arrayOfString = ["testingthisshouldbequiteabitlongerthan1word", "shorter", "s"];
    string[][] public dynArrayOfDynVal = [["testingthisshouldbequiteabitlongerthan1word"], ["shorter"], ["s"]];
    string public emptyString = "";

    event ValsSet(uint a, int b, bool c, int224 d, bool[2] e, int[] f, string g, string h, bytes16 i, bytes2[4][] j);

    function setValues(uint _uintVal, int _intVal, bool _boolVal, int224 _int224Val, bool[2] memory _boolVectorVal, int[] memory _intListVal, string memory _stringVal, string memory _emptyString, bytes16 _bytes16Val, bytes2[4][] memory _bytes2VectorListVal) public {
         uintVal =           _uintVal;
         intVal =            _intVal;
         boolVal =           _boolVal;
         int224Val =         _int224Val;
         boolVectorVal =     _boolVectorVal;
         intListVal =        _intListVal;
         stringVal   =       _stringVal;
         bytes16Val   =      _bytes16Val;
         bytes2VectorListVal = _bytes2VectorListVal;
         emptyString = _emptyString;

         emit ValsSet(_uintVal, _intVal, _boolVal, _int224Val, _boolVectorVal, _intListVal, _stringVal, emptyString, _bytes16Val, _bytes2VectorListVal);
    }

    function getVals () view public returns (
      uint,
      int,
      bool,
      int224,
      bool[2] memory,
      int[] memory,
      uint[] memory,
      string memory,
      string memory,
      bytes16,
      bytes2[4][]
      memory,
      string[] memory)
    {
      return (
        uintVal,
        intVal,
        boolVal,
        int224Val,
        boolVectorVal,
        intListVal,
        emptyArray,
        stringVal,
        emptyString,
        bytes16Val,
        bytes2VectorListVal,
        arrayOfString
      );
    }

    function getEmptyVals () view public returns (string memory, uint[] memory) {
        return (emptyString, emptyArray);
    }

    event DynString (string[] a);

    function arrayOfStrings() public returns(string[] memory) {
        emit DynString(arrayOfString);
        return arrayOfString;
    }
}

