// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import '../sft-factory/P12AssetFactoryUpgradable.sol';

contract P12AssetFactoryUpgradableAlter is P12AssetFactoryUpgradable {
  function setP12factory(address newAddr) public onlyOwner {
    p12factory = newAddr;
  }
}
