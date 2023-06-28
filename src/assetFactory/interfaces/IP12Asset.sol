// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.19;

interface IP12Asset {
  /**
   * @dev Update log of contract-level MetaData
   */
  event SetContractURI(string oldContractURI, string newContractURI);

  /**
   * @dev log of token metadata uri
   */
  event SetUri(uint256 id, string uri);

  error EmptyContractURI();
  error EmptyURI();
  error InvalidTokenId(uint256 tokenId);
  error MintExceedSupply(uint256 tokenId);

  function create(uint256, string calldata) external returns (uint256);

  function mint(
    address,
    uint256,
    uint256,
    bytes memory
  ) external;

  function setContractURI(string calldata) external;

  function setUri(uint256, string calldata) external;
}
