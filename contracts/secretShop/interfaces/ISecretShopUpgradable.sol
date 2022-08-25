// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;
import '../MarketConsts.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface ISecretShopUpgradable {
  /**
   * @dev event to record how much seller earns
   */
  event EvProfit(bytes32 itemHash, address currency, address to, uint256 amount);

  /**
   * @dev event to record a item order matched
   */
  event EvInventory(
    bytes32 indexed itemHash,
    address maker,
    address taker,
    uint256 orderSalt,
    uint256 settleSalt,
    uint256 intent,
    uint256 delegateType,
    uint256 deadline,
    IERC20Upgradeable currency,
    Market.OrderItem item,
    Market.SettleDetail detail
  );

  /**
   * @dev event to record delegator contract change
   */
  event EvDelegate(address delegate, bool isRemoval);

  /**
   * @dev event to record currency supported change
   */
  event EvCurrency(IERC20Upgradeable currency, bool isRemoval);

  /**
   * @dev event to record fee update
   */
  event EvFeeCapUpdate(uint256 newValue);
  /**
   * @dev event to record a order canceled
   */
  event EvCancel(bytes32 indexed itemHash);
  /**
   * @dev event to record a order failing
   */
  event EvFailure(uint256 index, bytes error);

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
