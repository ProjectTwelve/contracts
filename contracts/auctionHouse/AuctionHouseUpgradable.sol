// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import './interface/IDelegate.sol';
import './interface/IWETHUpgradable.sol';
import './MarketConsts.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

// import "hardhat/console.sol";

interface AuctionHouseRun {
  function run1(
    Market.Order memory order,
    Market.SettleShared memory shared,
    Market.SettleDetail memory detail
  ) external returns (uint256);
}

contract AuctionHouseUpgradable is
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  AuctionHouseRun,
  UUPSUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * @dev event to record how much seller earns
   */
  event EvProfit(bytes32 itemHash, address currency, address to, uint256 amount);
  // event EvAuctionRefund(bytes32 indexed itemHash, address currency, address to, uint256 amount, uint256 incentive);
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
    bytes dataMask,
    Market.OrderItem item,
    Market.SettleDetail detail
  );
  // event EvSigner(address signer, bool isRemoval);
  /**
   * @dev event to record delegator contract change
   */
  event EvDelegate(address delegate, bool isRemoval);
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

  /**
   * @dev store delegator contract status
   */
  mapping(address => bool) public delegates;
  // mapping(address => bool) public signers;

  /**
   * @dev store itemHash status
   */
  mapping(bytes32 => Market.InvStatus) public inventoryStatus;
  // mapping(bytes32 => Market.OngoingAuction) public ongoingAuctions;

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

  /** upgrade function */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  /**
   * @dev for contract to receive native token
   */
  receive() external payable {}

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function initialize(uint256 feeCapPct_, address weth_) public initializer {
    feeCapPct = feeCapPct_;
    weth = IWETHUpgradable(weth_);

    bytes32 EIP712DOMAIN_TYPEHASH = keccak256(
      'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );

    // if changed, not compatible with old version
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712DOMAIN_TYPEHASH,
        keccak256(bytes('P12 AuctionHouse')),
        keccak256(bytes('1.0.0')),
        block.chainid,
        address(this)
      )
    );

    __ReentrancyGuard_init_unchained();
    __Pausable_init_unchained();
    __Ownable_init_unchained();
  }

  function updateFeeCap(uint256 val) public virtual onlyOwner {
    feeCapPct = val;
    emit EvFeeCapUpdate(val);
  }

  // /**
  //  * @dev not necessary at v1
  //  */
  // function updateSigners(address[] memory toAdd, address[] memory toRemove)
  //     public
  //     virtual
  //     onlyOwner
  // {
  //     for (uint256 i = 0; i < toAdd.length; i++) {
  //         signers[toAdd[i]] = true;
  //         emit EvSigner(toAdd[i], false);
  //     }
  //     for (uint256 i = 0; i < toRemove.length; i++) {
  //         delete signers[toRemove[i]];
  //         emit EvSigner(toRemove[i], true);
  //     }
  // }

  /**
   * @dev update Delegates address
   */
  function updateDelegates(address[] memory toAdd, address[] memory toRemove) public virtual onlyOwner {
    for (uint256 i = 0; i < toAdd.length; i++) {
      delegates[toAdd[i]] = true;
      emit EvDelegate(toAdd[i], false);
    }
    for (uint256 i = 0; i < toRemove.length; i++) {
      delete delegates[toRemove[i]];
      emit EvDelegate(toRemove[i], true);
    }
  }

  // /**
  //  * @dev cancel order
  //  * @dev why deadline: if tx's gas price is not high enough, this tx will be pending forever.
  //  */
  // function cancel(
  //   bytes32[] memory itemHashes,
  //   uint256 deadline,
  //   uint8 v,
  //   bytes32 r,
  //   bytes32 s
  // ) public virtual nonReentrant whenNotPaused {
  //   require(deadline > block.timestamp, 'AuctionHouse: deadline reached');
  //   // bytes32 hash = keccak256(
  //   //     abi.encode(itemHashes.length, itemHashes, deadline)
  //   // );
  //   // address signer = ECDSA.recover(hash, v, r, s);
  //   // require(signers[signer], "Input signature error");

  //   for (uint256 i = 0; i < itemHashes.length; i++) {
  //     bytes32 h = itemHashes[i];
  //     if (inventoryStatus[h] == Market.InvStatus.NEW) {
  //       inventoryStatus[h] = Market.InvStatus.CANCELLED;
  //       emit EvCancel(h);
  //     }
  //   }
  // }

  /**
   * @dev Entry of a contract call
   */
  function run(Market.RunInput memory input) public payable virtual nonReentrant whenNotPaused {
    require(input.shared.deadline > block.timestamp, 'AuctionHouse: deadline reached');
    require(msg.sender == input.shared.user, 'AuctionHouse: sender not match');

    /**
            not necessary to limit signer at v1
         */
    // _verifyInputSignature(input);

    uint256 amountEth = msg.value;

    /**
     * no weth at v1
     */
    // if (input.shared.amountToWeth > 0) {
    //     uint256 amt = input.shared.amountToWeth;
    //     weth.deposit{value: amt}();
    //     SafeERC20Upgradeable.safeTransfer(weth, msg.sender, amt);
    //     amountEth -= amt;
    // }

    /**
     * @dev not necessary to send eth now
     */
    // if (input.shared.amountToEth > 0) {
    //     uint256 amt = input.shared.amountToEth;
    //     SafeERC20Upgradeable.safeTransferFrom(
    //         weth,
    //         msg.sender,
    //         address(this),
    //         amt
    //     );
    //     weth.withdraw(amt);
    //     amountEth += amt;
    // }

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
        try AuctionHouseRun(address(this)).run1(order, input.shared, detail) returns (uint256 ethPayment) {
          amountEth -= ethPayment;
        } catch Error(string memory _err) {
          emit EvFailure(i, bytes(_err));
        } catch (bytes memory _err) {
          emit EvFailure(i, _err);
        }
      } else {
        amountEth -= _run(order, input.shared, detail);
      }
    }
    // /**
    //  * @dev if more eth, transfer back
    //  */
    // if (amountEth > 0) {
    //     payable(msg.sender).transfer(amountEth);
    // }
  }

  /**
   * @dev run a single order
   */
  function run1(
    Market.Order memory order,
    Market.SettleShared memory shared,
    Market.SettleDetail memory detail
  ) external virtual override returns (uint256) {
    require(msg.sender == address(this), 'AuctionHouse: unsafe call');

    return _run(order, shared, detail);
  }

  /**
   * @dev hash an item Data to calculate itemHash
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
          order.dataMask,
          item
        )
      );
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
      order.dataMask,
      item,
      detail
    );
  }

  /**
   *
   * @dev make single trade to be achieved
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
      require(itemHash == detail.itemHash, 'AuctionHouse: hash not match');
      require(order.network == block.chainid, 'AuctionHouse: wrong network');
      require(
        address(detail.executionDelegate) != address(0) && delegates[address(detail.executionDelegate)],
        'AuctionHouse: unknown delegate'
      );
    }

    bytes memory data = item.data;
    /**
     * @dev recover masked data, not necessary at v1
     */
    // {
    //     if (
    //         order.dataMask.length > 0 && detail.dataReplacement.length > 0
    //     ) {
    //         _arrayReplace(data, detail.dataReplacement, order.dataMask);
    //     }
    // }

    if (detail.op == Market.Op.COMPLETE_SELL_OFFER) {
      /** @dev COMPLETE_SELL_OFFER */
      require(inventoryStatus[itemHash] == Market.InvStatus.NEW, 'AuctionHouse: sold or canceled');
      require(order.intent == Market.INTENT_SELL, 'AuctionHouse: intent != sell');
      _assertDelegation(order, detail);
      require(order.deadline > block.timestamp, 'AuctionHouse: deadline reached');
      require(detail.price >= item.price, 'AuctionHouse: underpaid');

      /**
       * @dev transfer token from buyer address to this contract
       * note no native token until now
       */
      nativeAmount = _takePayment(itemHash, order.currency, shared.user, detail.price);
      require(detail.executionDelegate.executeSell(order.user, shared.user, data), 'AuctionHouse: delegation error');

      _distributeFeeAndProfit(itemHash, order.user, order.currency, detail, detail.price, detail.price);
      inventoryStatus[itemHash] = Market.InvStatus.COMPLETE;
    }
    /** no need to deal with buy offer now */
    // else if (detail.op == Market.Op.COMPLETE_BUY_OFFER) {
    //     require(
    //         inventoryStatus[itemHash] == Market.InvStatus.NEW,
    //         "order already exists"
    //     );
    //     require(order.intent == Market.INTENT_BUY, "intent != buy");
    //     _assertDelegation(order, detail);
    //     require(order.deadline > block.timestamp, "deadline reached");
    //     require(item.price == detail.price, "price not match");
    //     require(!_isNative(order.currency), "native token not supported");
    //     nativeAmount = _takePayment(
    //         itemHash,
    //         order.currency,
    //         order.user,
    //         detail.price
    //     );
    //     require(
    //         detail.executionDelegate.executeBuy(
    //             shared.user,
    //             order.user,
    //             data
    //         ),
    //         "delegation error"
    //     );
    //     _distributeFeeAndProfit(
    //         itemHash,
    //         shared.user,
    //         order.currency,
    //         detail,
    //         detail.price,
    //         detail.price
    //     );
    //     inventoryStatus[itemHash] = Market.InvStatus.COMPLETE;
    // }
    else if (detail.op == Market.Op.CANCEL_OFFER) {
      /** CANCEL_OFFER */
      require(inventoryStatus[itemHash] == Market.InvStatus.NEW, 'AuctionHouse: unable to cancel');
      require(order.user == msg.sender, 'AuctionHouse: no permit cancel');
      require(order.deadline > block.timestamp, 'AuctionHouse: deadline reached');
      inventoryStatus[itemHash] = Market.InvStatus.CANCELLED;
      emit EvCancel(itemHash);
    }
    /**
     * not necessary to deal with bid
     */
    // else if (detail.op == Market.Op.BID) {
    //     require(order.intent == Market.INTENT_AUCTION, "intent != auction");
    //     _assertDelegation(order, detail);
    //     bool firstBid = false;
    //     if (ongoingAuctions[itemHash].bidder == address(0)) {
    //         require(
    //             inventoryStatus[itemHash] == Market.InvStatus.NEW,
    //             "order already exists"
    //         );
    //         require(order.deadline > block.timestamp, "auction ended");
    //         require(detail.price >= item.price, "underpaid");
    //         firstBid = true;
    //         ongoingAuctions[itemHash] = Market.OngoingAuction({
    //             price: detail.price,
    //             netPrice: detail.price,
    //             bidder: shared.user,
    //             endAt: order.deadline
    //         });
    //         inventoryStatus[itemHash] = Market.InvStatus.AUCTION;
    //         require(
    //             detail.executionDelegate.executeBid(
    //                 order.user,
    //                 address(0),
    //                 shared.user,
    //                 data
    //             ),
    //             "delegation error"
    //         );
    //     }
    //     Market.OngoingAuction storage auc = ongoingAuctions[itemHash];
    //     require(auc.endAt > block.timestamp, "auction ended");
    //     nativeAmount = _takePayment(
    //         itemHash,
    //         order.currency,
    //         shared.user,
    //         detail.price
    //     );
    //     if (!firstBid) {
    //         require(
    //             inventoryStatus[itemHash] == Market.InvStatus.AUCTION,
    //             "order is not auction"
    //         );
    //         require(
    //             detail.price - auc.price >=
    //                 (auc.price * detail.aucMinIncrementPct) / RATE_BASE,
    //             "underbid"
    //         );
    //         uint256 bidRefund = auc.netPrice;
    //         uint256 incentive = (detail.price * detail.bidIncentivePct) /
    //             RATE_BASE;
    //         if (bidRefund + incentive > 0) {
    //             _transferTo(
    //                 order.currency,
    //                 auc.bidder,
    //                 bidRefund + incentive
    //             );
    //             emit EvAuctionRefund(
    //                 itemHash,
    //                 address(order.currency),
    //                 auc.bidder,
    //                 bidRefund,
    //                 incentive
    //             );
    //         }
    //         require(
    //             detail.executionDelegate.executeBid(
    //                 order.user,
    //                 auc.bidder,
    //                 shared.user,
    //                 data
    //             ),
    //             "delegation error"
    //         );
    //         auc.price = detail.price;
    //         auc.netPrice = detail.price - incentive;
    //         auc.bidder = shared.user;
    //     }
    //     if (block.timestamp + detail.aucIncDurationSecs > auc.endAt) {
    //         auc.endAt += detail.aucIncDurationSecs;
    //     }
    // } else if (
    //     detail.op == Market.Op.REFUND_AUCTION ||
    //     detail.op == Market.Op.REFUND_AUCTION_STUCK_ITEM
    // ) {
    //     require(
    //         inventoryStatus[itemHash] == Market.InvStatus.AUCTION,
    //         "cannot cancel non-auction order"
    //     );
    //     Market.OngoingAuction storage auc = ongoingAuctions[itemHash];
    //     if (auc.netPrice > 0) {
    //         _transferTo(order.currency, auc.bidder, auc.netPrice);
    //         emit EvAuctionRefund(
    //             itemHash,
    //             address(order.currency),
    //             auc.bidder,
    //             auc.netPrice,
    //             0
    //         );
    //     }
    //     _assertDelegation(order, detail);
    //     if (detail.op == Market.Op.REFUND_AUCTION) {
    //         require(
    //             detail.executionDelegate.executeAuctionRefund(
    //                 order.user,
    //                 auc.bidder,
    //                 data
    //             ),
    //             "delegation error"
    //         );
    //     }
    //     delete ongoingAuctions[itemHash];
    //     inventoryStatus[itemHash] = Market.InvStatus.REFUNDED;
    // } else if (detail.op == Market.Op.COMPLETE_AUCTION) {
    //     require(
    //         inventoryStatus[itemHash] == Market.InvStatus.AUCTION,
    //         "cannot complete non-auction order"
    //     );
    //     _assertDelegation(order, detail);
    //     Market.OngoingAuction storage auc = ongoingAuctions[itemHash];
    //     require(block.timestamp >= auc.endAt, "auction not finished yet");
    //     require(
    //         detail.executionDelegate.executeAuctionComplete(
    //             order.user,
    //             auc.bidder,
    //             data
    //         ),
    //         "delegation error"
    //     );
    //     _distributeFeeAndProfit(
    //         itemHash,
    //         order.user,
    //         order.currency,
    //         detail,
    //         auc.price,
    //         auc.netPrice
    //     );
    //     inventoryStatus[itemHash] = Market.InvStatus.COMPLETE;
    //     delete ongoingAuctions[itemHash];
    // }
    else {
      revert('AuctionHouse: unknown op');
    }

    _emitInventory(itemHash, order, item, shared, detail);
    return nativeAmount;
  }

  /**
   * @dev judge delegate type
   */
  function _assertDelegation(Market.Order memory order, Market.SettleDetail memory detail) internal view virtual {
    require(detail.executionDelegate.delegateType() == order.delegateType, 'AuctionHouse: delegation error');
  }

  // modifies `src`
  // function _arrayReplace(
  //   bytes memory src,
  //   bytes memory replacement,
  //   bytes memory mask
  // ) internal view virtual {
  //   require(src.length == replacement.length);
  //   require(src.length == mask.length);

  //   for (uint256 i = 0; i < src.length; i++) {
  //     if (mask[i] != 0) {
  //       src[i] = replacement[i];
  //     }
  //   }
  // }

  // /**
  //  * @dev allow some address to trade, may be these who sign in nft market
  //  * not necessary to verify at v1
  //  */
  // function _verifyInputSignature(Market.RunInput memory input) internal view virtual {
  //   bytes32 hashValue = keccak256(abi.encode(input.shared, input.details.length, input.details));
  //   address signer = ECDSA.recover(hashValue, input.v, input.r, input.s);
  //   require(signers[signer], 'AuctionHouse: Input sig error');
  // }

  /**
   * @dev hash typed data of an Order
   */
  function _hash(Market.Order memory order) private pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            'Order(uint256 salt,address user,uint256 network,uint256 intent,uint256 delegateType,uint256 deadline,address currency,bytes dataMask,uint256 length,OrderItem[] items)OrderItem(uint256 price,bytes data)'
          ),
          order.salt,
          order.user,
          order.network,
          order.intent,
          order.delegateType,
          order.deadline,
          order.currency,
          keccak256(order.dataMask),
          order.items.length,
          _hash(order.items)
        )
      );
  }

  /**
   * @dev hash typed data of a array of OderItem
   */
  function _hash(Market.OrderItem[] memory orderItems) private pure returns (bytes32) {
    bytes memory h;
    for (uint256 i = 0; i < orderItems.length; i++) {
      h = abi.encodePacked(h, _hash(orderItems[i]));
    }
    // return keccak256(abi.encode(hash(orderItems[0])));
    return keccak256(h);
  }

  /**
   * @dev hash typed data of an OrderItem
   */

  function _hash(Market.OrderItem memory orderItem) private pure returns (bytes32) {
    return keccak256(abi.encode(keccak256('OrderItem(uint256 price,bytes data)'), orderItem.price, keccak256(orderItem.data)));
  }

  /**
   * @dev verify whether the order data is real
   * @dev necessary for security
   */
  function _verifyOrderSignature(Market.Order memory order) internal view virtual {
    address orderSigner;

    if (order.signVersion == Market.SIGN_V1) {
      bytes32 dataHash = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, _hash(order));
      orderSigner = ECDSA.recover(dataHash, order.v, order.r, order.s);
    } else {
      revert('AuctionHouse: wrong sig version');
    }

    require(orderSigner == order.user, 'AuctionHouse: sig not match');
  }

  /**
   * @dev judge whether token is chain native token
   */
  function _isNative(IERC20Upgradeable currency) internal view virtual returns (bool) {
    return address(currency) == address(0);
  }

  /**
   * @dev transfer some kind ERC20 to this contract
   */

  function _takePayment(
    bytes32 itemHash,
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
   */
  function _distributeFeeAndProfit(
    bytes32 itemHash,
    address seller,
    IERC20Upgradeable currency,
    Market.SettleDetail memory sd,
    uint256 price,
    uint256 netPrice
  ) internal virtual {
    require(price >= netPrice, 'price error');

    uint256 payment = netPrice;
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
}
