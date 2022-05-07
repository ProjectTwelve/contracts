// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

abstract contract P12AssetFactoryUpgradableStorage {
  /**
    @dev collection address => gameId
  */
  mapping(address => string) public registry;

  /**
   * p12factory address, for reading game and developer relationship
   */
  address public p12factory;
}
