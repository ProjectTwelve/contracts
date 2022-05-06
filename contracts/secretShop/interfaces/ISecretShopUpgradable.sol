// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../MarketConsts.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface ISecretShopUpgradable {
  function runSingle(
    Market.Order memory,
    Market.SettleShared memory,
    Market.SettleDetail memory
  ) external returns (uint256);

  function updateFeeCap(uint256) external;

  function updateDelegates(address[] calldata, address[] calldata) external;

  function updateCurrencies(IERC20Upgradeable[] calldata, IERC20Upgradeable[] calldata) external;

  function run(Market.RunInput memory input) external payable;
}
