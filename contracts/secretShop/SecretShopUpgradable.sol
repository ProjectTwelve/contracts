// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import './interfaces/IDelegate.sol';
import './interfaces/IWETHUpgradable.sol';

import './interfaces/ISecretShopUpgradable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './SecretShopStorage.sol';
import '../access/SafeOwnableUpgradeable.sol';

contract SecretShopUpgradable is
  SecretShopStorage,
  ISecretShopUpgradable,
  ReentrancyGuardUpgradeable,
  SafeOwnableUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /** @dev precision of the parameters */
  uint256 public constant RATE_BASE = 1e6;

  /**
   * @dev for contract to receive native token
   */
  receive() external payable {}

  /**
   * @dev run a single order
   * @param order order by the maker
   * @param shared some option of the taker
   * @param detail detail by the taker
   */
  function runSingle(
    Market.Order memory order,
    Market.SettleShared memory shared,
    Market.SettleDetail memory detail
  ) external virtual override returns (uint256) {
    require(msg.sender == address(this), 'SecretShop: unsafe call');

    return _run(order, shared, detail);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @dev initialize
   * @param feeCapPct_ max fee percentage
   * @param weth_ address of wrapped eth
   */
  function initialize(uint256 feeCapPct_, address weth_) public initializer {
    feeCapPct = feeCapPct_;
    weth = IWETHUpgradable(weth_);
    bytes32 eip712DomainTypeHash = keccak256(
      'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );

    // if changed, not compatible with old version
    domainSeparator = keccak256(
      abi.encode(
        eip712DomainTypeHash,
        keccak256(bytes('P12 SecretShop')),
        keccak256(bytes('1.0.0')),
        block.chainid,
        address(this)
      )
    );

    __ReentrancyGuard_init_unchained();
    __Pausable_init_unchained();
    __Ownable_init_unchained();
  }

  /**
   * @param val new Fee Cap
   */
  function updateFeeCap(uint256 val) public virtual override onlyOwner {
    feeCapPct = val;
    emit EvFeeCapUpdate(val);
  }

  /**
   * @dev update Delegates address
   * @param toAdd the array of delegate address that want to add
   * @param toRemove the array to delegate address that want to remove
   */
  function updateDelegates(address[] calldata toAdd, address[] calldata toRemove) public virtual override onlyOwner {
    for (uint256 i = 0; i < toAdd.length; i++) {
      delegates[toAdd[i]] = true;
      emit EvDelegate(toAdd[i], false);
    }
    for (uint256 i = 0; i < toRemove.length; i++) {
      delete delegates[toRemove[i]];
      emit EvDelegate(toRemove[i], true);
    }
  }

  /**
   * @dev update Currencies address
   * @param toAdd the array of currency address that want to add
   * @param toRemove the array to currency address that want to remove
   */
  function updateCurrencies(IERC20Upgradeable[] memory toAdd, IERC20Upgradeable[] memory toRemove) public override onlyOwner {
    for (uint256 i = 0; i < toAdd.length; i++) {
      currencies[toAdd[i]] = true;
      emit EvCurrency(toAdd[i], false);
    }
    for (uint256 i = 0; i < toRemove.length; i++) {
      delete currencies[toRemove[i]];
      emit EvCurrency(toRemove[i], true);
    }
  }

  /**
   * @dev Entry of a contract call
   * @param input a struct that contains all data
   */
  function run(Market.RunInput memory input) public payable virtual override nonReentrant whenNotPaused {
    require(input.shared.deadline > block.timestamp, 'SecretShop: deadline reached');
    require(msg.sender == input.shared.user, 'SecretShop: sender not match');

    uint256 amountEth = msg.value;

    /**
     * @dev Iterate over multiple orders and verify signatures
     */
    for (uint256 i = 0; i < input.orders.length; i++) {
      _verifyOrderSignature(input.orders[i]);
    }

    /**
     * @dev try to execute after verify
     */
    for (uint256 i = 0; i < input.details.length; i++) {
      Market.SettleDetail memory detail = input.details[i];
      Market.Order memory order = input.orders[detail.orderIdx];
      if (input.shared.canFail) {
        try ISecretShopUpgradable(address(this)).runSingle(order, input.shared, detail) returns (uint256 ethPayment) {
          amountEth -= ethPayment;
        } catch Error(string memory err) {
          emit EvFailure(i, bytes(err));
        } catch (bytes memory err) {
          emit EvFailure(i, err);
        }
      } else {
        amountEth -= _run(order, input.shared, detail);
      }
    }
  }

  function _emitInventory(
    bytes32 itemHash,
    Market.Order memory order,
    Market.OrderItem memory item,
    Market.SettleShared memory shared,
    Market.SettleDetail memory detail
  ) internal virtual {
    emit EvInventory(
      itemHash,
      order.user,
      shared.user,
      order.salt,
      shared.salt,
      order.intent,
      order.delegateType,
      order.deadline,
      order.currency,
      item,
      detail
    );
  }

  /**
   * @dev internal function, real implementation
   * @dev make single trade to be achieved
   * @param order order by the maker
   * @param shared some option of the taker
   * @param detail detail by the taker
   */
  function _run(
    Market.Order memory order,
    Market.SettleShared memory shared,
    Market.SettleDetail memory detail
  ) internal virtual returns (uint256) {
    uint256 nativeAmount = 0;

    Market.OrderItem memory item = order.items[detail.itemIdx];
    bytes32 itemHash = _hashItem(order, item);

    {
      require(itemHash == detail.itemHash, 'SecretShop: hash not match');
      require(order.network == block.chainid, 'SecretShop: wrong network');
      require(
        address(detail.executionDelegate) != address(0) && delegates[address(detail.executionDelegate)],
        'SecretShop: unknown delegate'
      );
      require(currencies[order.currency], 'SecretShop: wrong currency');
    }

    bytes memory data = item.data;

    if (detail.op == Market.Op.COMPLETE_SELL_OFFER) {
      /** @dev COMPLETE_SELL_OFFER */
      require(inventoryStatus[itemHash] == Market.InvStatus.NEW, 'SecretShop: sold or canceled');
      require(order.intent == Market.INTENT_SELL, 'SecretShop: intent != sell');
      _assertDelegation(order, detail);
      require(order.deadline > block.timestamp, 'SecretShop: deadline reached');
      require(detail.price >= item.price, 'SecretShop: underpaid');

      /**
       * @dev transfer token from buyer address to this contract
       */
      nativeAmount = _takePayment(order.currency, shared.user, detail.price);
      require(detail.executionDelegate.executeSell(order.user, shared.user, data), 'SecretShop: delegation error');

      _distributeFeeAndProfit(itemHash, order.user, order.currency, detail, detail.price);
      inventoryStatus[itemHash] = Market.InvStatus.COMPLETE;
    } else if (detail.op == Market.Op.CANCEL_OFFER) {
      /** CANCEL_OFFER */
      require(inventoryStatus[itemHash] == Market.InvStatus.NEW, 'SecretShop: unable to cancel');
      require(order.user == msg.sender, 'SecretShop: no permit cancel');
      require(order.deadline > block.timestamp, 'SecretShop: deadline reached');
      inventoryStatus[itemHash] = Market.InvStatus.CANCELLED;
      emit EvCancel(itemHash);
    } else {
      revert('SecretShop: unknown op');
    }

    _emitInventory(itemHash, order, item, shared, detail);
    return nativeAmount;
  }

  /**
   * @dev transfer some kind ERC20 to this contract
   * @param currency currency's address
   * @param from who pays
   * @param amount how much pay
   */
  function _takePayment(
    IERC20Upgradeable currency,
    address from,
    uint256 amount
  ) internal virtual returns (uint256) {
    if (amount > 0) {
      if (_isNative(currency)) {
        return amount;
      } else {
        currency.safeTransferFrom(from, address(this), amount);
      }
    }
    return 0;
  }

  /**
   * @dev transfer some kind ERC20
   * @param currency currency's address
   * @param to who receive
   * @param amount how much receive
   */
  function _transferTo(
    IERC20Upgradeable currency,
    address to,
    uint256 amount
  ) internal virtual {
    if (amount > 0) {
      if (_isNative(currency)) {
        AddressUpgradeable.sendValue(payable(to), amount);
      } else {
        currency.safeTransfer(to, amount);
      }
    }
  }

  /**
   * @dev distribute fees and give extra to seller
   * @param itemHash the item's hash
   * @param seller who sell the item
   * @param currency currency's address
   * @param sd detail by the taker
   * @param price the item's price
   */
  function _distributeFeeAndProfit(
    bytes32 itemHash,
    address seller,
    IERC20Upgradeable currency,
    Market.SettleDetail memory sd,
    uint256 price
  ) internal virtual {
    uint256 payment = price;
    uint256 totalFeePct;

    /**
     * @dev distribute fees
     */
    for (uint256 i = 0; i < sd.fees.length; i++) {
      Market.Fee memory fee = sd.fees[i];
      totalFeePct += fee.percentage;
      uint256 amount = (price * fee.percentage) / RATE_BASE;
      payment -= amount;
      _transferTo(currency, fee.to, amount);
    }

    require(feeCapPct >= totalFeePct, 'total fee cap exceeded');

    /**
     * @dev give extra to seller
     */
    _transferTo(currency, seller, payment);
    emit EvProfit(itemHash, address(currency), seller, payment);
  }

  /** upgrade function */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  /**
   * @dev judge whether token is chain native token
   * @param currency address of the currency, 0 for native token
   * @return bool whether the token is a native token
   */
  function _isNative(IERC20Upgradeable currency) internal view virtual returns (bool) {
    return address(currency) == address(0);
  }

  /**
   * @dev verify whether the order data is real, necessary for security
   * @param order order by the maker
   */
  function _verifyOrderSignature(Market.Order memory order) internal view virtual {
    address orderSigner;

    if (order.signVersion == Market.SIGN_V1) {
      bytes32 dataHash = ECDSA.toTypedDataHash(domainSeparator, _hash(order));
      orderSigner = ECDSA.recover(dataHash, order.v, order.r, order.s);
    } else {
      revert('SecretShop: wrong sig version');
    }

    require(orderSigner == order.user, 'SecretShop: sig not match');
  }

  /**
   * @dev hash an item Data to calculate itemHash
   * @param order order by the maker
   * @param item which item to be hashed in the order
   * @return hash the item's hash, which is unique
   */
  function _hashItem(Market.Order memory order, Market.OrderItem memory item) internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          order.salt,
          order.user,
          order.network,
          order.intent,
          order.delegateType,
          order.deadline,
          order.currency,
          item
        )
      );
  }

  /**
   * @dev judge delegate type
   * @param order order by the maker
   * @param detail settle detail by the taker
   */
  function _assertDelegation(Market.Order memory order, Market.SettleDetail memory detail) internal view virtual {
    require(detail.executionDelegate.delegateType() == order.delegateType, 'SecretShop: delegation error');
  }

  /**
   * @dev hash typed data of an Order
   * @param order order by the maker
   * @return hash typed data hash
   */
  function _hash(Market.Order memory order) private pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            'Order(uint256 salt,address user,uint256 network,uint256 intent,uint256 delegateType,uint256 deadline,address currency,uint256 length,OrderItem[] items)OrderItem(uint256 price,bytes data)'
          ),
          order.salt,
          order.user,
          order.network,
          order.intent,
          order.delegateType,
          order.deadline,
          order.currency,
          order.items.length,
          _hash(order.items)
        )
      );
  }

  /**
   * @dev hash typed data of a array of orderItem
   * @param orderItems[] the array of the orderItem
   * @return hash typed data hash
   */
  function _hash(Market.OrderItem[] memory orderItems) private pure returns (bytes32) {
    bytes memory h;
    for (uint256 i = 0; i < orderItems.length; i++) {
      h = abi.encodePacked(h, _hash(orderItems[i]));
    }
    return keccak256(h);
  }

  /**
   * @dev hash typed data of an orderItem
   * @param orderItem orderItem
   * @return hash typed data hash
   */

  function _hash(Market.OrderItem memory orderItem) private pure returns (bytes32) {
    return keccak256(abi.encode(keccak256('OrderItem(uint256 price,bytes data)'), orderItem.price, keccak256(orderItem.data)));
  }
}
