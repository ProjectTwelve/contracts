// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IP12Asset {
  /**
   * @dev Update log of contract-level MetaData
   */
  event SetContractURI(string oldContractURI, string newContractURI_);

  /**
   * @dev log of token metadata uri
   */
  event SetUri(uint256 id, string uri_);

  function create(uint256, string calldata) external returns (uint256);

  function mint(
    address,
    uint256,
    uint256,
    bytes memory
  ) external;

  function setContractURI(string calldata) external;
}
