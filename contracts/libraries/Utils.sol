pragma solidity 0.8.13;

library Utils {
  function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}
