// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IWETHUpgradable is IERC20Upgradeable {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}
