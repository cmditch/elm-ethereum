pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;


contract ComplexStorage {
    uint uintVal = 123;
    int intVal = -128;
    bool boolVal = true;
    int224 int224Val = -999999999999999999999999999999999999999999999999999999999999999;
    bool[2] boolVectorVal = [true, false];
    int[] intListVal = [1, 2, 3, int224Val, -10, 1, 2, 34];
    string stringVal = "wtf mate";
    bytes16 bytes16Val = "1234567890123456";
    bytes2 a = 0x1234;
    bytes2 b = 0x5678;
    bytes2 c = 0xffff;
    bytes2[4] bytes2Vector = [a, b, c];
    bytes2[4][] bytes2VectorListVal = [bytes2Vector, bytes2Vector, bytes2Vector];
    string[] arrayOfString = ["testingthisshouldbequiteabitlongerthan1word", "", "shorter", "s"];
    string[][] dynArrayOfDynVal = [["testingthisshouldbequiteabitlongerthan1word"], [""], ["shorter"], ["s"]];
    uint[] emptyArray;
    string emptyString;
    bytes emptyBytes;

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

    function test1 () public view returns (
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
      bytes2[4][] memory,
      bytes memory
    )
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
        emptyBytes
      );
    }

    function test2 () public view returns (
      // string[][] memory,
      string[] memory
    )
    {
      return (
        // dynArrayOfDynVal,
        arrayOfString
      );
    }
}

