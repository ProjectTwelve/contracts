// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IP12AssetFactoryUpgradable {
  /**
   * @dev record a new Collection Created
   */
  event CollectionCreated(address indexed collection, address indexed developer);

  /**
   * @dev record a new Sft created, sft is semi-fungible token, as it's in a ERC1155 contract
   */
  event SftCreated(address indexed collection, uint256 indexed tokenId, uint256 amount);

  function createCollection(string calldata gameId, string calldata) external;

  function createAssetAndMint(
    address,
    uint256,
    string calldata
  ) external;

  function updateCollectionUri(address, string calldata) external;

  function updateSftUri(
    address,
    uint256,
    string calldata
  ) external;
}
