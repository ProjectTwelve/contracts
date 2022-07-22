// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import '../sft-factory/P12AssetFactoryUpgradable.sol';

contract P12AssetFactoryUpgradableAlter is P12AssetFactoryUpgradable {
  function setP12factory(address newAddr) public onlyOwner {
    require(newAddr != address(0), 'P12AssetF: address cannot be 0');
    p12factory = newAddr;
  }
}
