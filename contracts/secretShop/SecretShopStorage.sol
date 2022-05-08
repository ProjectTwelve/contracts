// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './MarketConsts.sol';

abstract contract SecretShopStorage {
  /**
   * @dev store delegator contract status
   */
  mapping(address => bool) public delegates;

  /**
   * @dev store currency supported
   */
  mapping(IERC20Upgradeable => bool) public currencies;

  /**
   * @dev store itemHash status
   */
  mapping(bytes32 => Market.InvStatus) public inventoryStatus;

  /**
   * @dev fee Cap
   */
  uint256 public feeCapPct;
  /**
   * @dev DOMAIN_SEPARATOR for EIP712
   */
  bytes32 public domainSeparator;

  IWETHUpgradable public weth;
}
