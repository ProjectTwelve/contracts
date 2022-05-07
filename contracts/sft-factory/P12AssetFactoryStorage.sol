// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract P12AssetFactoryStorage {
  /**
    @dev collection address => gameId
  */
  mapping(address => string) public registry;

  /**
   * p12factory address, for reading game and developer relationship
   */
  address public p12factory;
}
