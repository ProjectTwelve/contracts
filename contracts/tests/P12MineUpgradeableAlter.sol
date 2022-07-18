// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '../staking/P12MineUpgradeable.sol';

contract P12MineUpgradeableAlter is P12MineUpgradeable {
  function setP12factory(address newAddr) public onlyOwner {
    p12Factory = newAddr;
  }
}
