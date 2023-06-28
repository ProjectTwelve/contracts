// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;
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

  /// @dev signature deadline reached
  error DeadlineReached();
  /// @dev msg.sender is not the address in data
  error SenderNotMatch();
  /// @dev signature not match to msg.sender;
  error SignatureNotMatch();
  /// @dev signature version not match
  error SignatureVersionNotMatch();
  /// @dev itemHash not match to data hashed
  error ItemHashNotMatch();
  /// @dev item cannot be traded because sold or cancelled;
  error ItemNotListed(bytes32 itemHash);
  /// @dev intent not match
  error IntentNotMath();
  /// @dev price not match, such as price given is lower than price offered now
  error ItemPriceNotMath();
  /// @dev chain Id not match
  error NetworkNotMatch();
  /// @dev wrong currency, the erc20 currency is not allowed
  error NotWhiteCurrency();
  /// @dev invalid delegate parameter
  error InvalidDelegate();
  /// @dev delegate execute fail
  error ExecuteDelegateFail();
  /// @dev fee cap exceed
  error FeeCapExceed();
  /// @dev refund extra token fail
  error ReFundTokenFail();
  /// @dev restrict the caller must be address(this)
  error UnSafeCall();

  function runSingle(
    Market.Order memory,
    Market.SettleShared memory,
    Market.SettleDetail memory
  ) external returns (uint256);

  function updateFeeCap(uint256) external;

  function updateDelegates(address[] calldata, address[] calldata) external;

  function updateCurrencies(IERC20Upgradeable[] calldata, IERC20Upgradeable[] calldata) external;

  /**
   * @dev verify whether the order data is real, necessary for security
   * @param order order by the maker
   */
  function verifyOrderSignature(Market.Order memory order) external view returns (bool);

  function run(Market.RunInput memory input) external payable;
}
