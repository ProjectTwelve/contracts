// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract P12AssetStorage {
  /**
   * @dev contract-level metadata uri, refer to https://docs.opensea.io/docs/contract-level-metadata
   */
  string public contractURI;

  /**
   * @dev current supply, how many a id are minted not.
   */
  mapping(uint256 => uint256) public supply;

  /**
   * @dev max supply, a token id has a max supply cap
   */
  mapping(uint256 => uint256) public maxSupply;
}
