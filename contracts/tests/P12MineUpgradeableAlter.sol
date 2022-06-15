// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import '../staking/P12MineUpgradeable.sol';
import '../factory/interfaces/IP12V0FactoryUpgradeable.sol';

contract P12MineUpgradeableAlter is P12MineUpgradeable {
  function setP12factory(IP12V0FactoryUpgradeable newAddr) public onlyOwner {
    p12Factory = newAddr;
  }
}
