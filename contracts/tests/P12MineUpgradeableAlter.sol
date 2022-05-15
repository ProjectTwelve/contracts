// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import '../staking/P12MineUpgradeable.sol';

contract P12MineUpgradeableAlter is P12MineUpgradeable {
  function setP12factory(address newAddr) public onlyOwner {
    p12Factory = newAddr;
  }
}
