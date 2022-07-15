// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

contract P12AssetFactoryStorage {
  /**
    @dev collection address => gameId
  */
  mapping(address => string) public registry;

  /**
   * p12factory address, for reading game and developer relationship
   */
  address public p12factory;

  uint256[49] private __gap;
}
