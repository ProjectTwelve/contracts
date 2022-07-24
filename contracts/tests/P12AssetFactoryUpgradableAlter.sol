// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import '../sftFactory/P12AssetFactoryUpgradable.sol';

contract P12AssetFactoryUpgradableAlter is P12AssetFactoryUpgradable {
  function setP12factory(address newAddr) public onlyOwner {
    p12factory = newAddr;
  }
}
