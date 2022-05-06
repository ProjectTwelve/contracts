// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IP12AssetFactoryUpgradable {
  function createCollection(string calldata gameId, string calldata) external;

  function createAssetAndMint(
    address,
    uint256,
    string calldata
  ) external;

  function updateCollectionUri(address, string calldata) external;
}
