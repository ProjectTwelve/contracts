// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './MarketConsts.sol';

abstract contract SecretShopUpgradableStorage {
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

  /** @dev precision of the parameters */
  uint256 public constant RATE_BASE = 1e6;
  /**
   * @dev fee Cap
   */
  uint256 public feeCapPct;
  /**
   * @dev DOMAIN_SEPARATOR for EIP712
   */
  bytes32 public DOMAIN_SEPARATOR;

  IWETHUpgradable public weth;
}
