// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import './interfaces/IDelegate.sol';
import './interfaces/IWETHUpgradable.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

library Market {
  uint256 public constant INTENT_SELL = 1;

  uint8 public constant SIGN_V1 = 1;

  struct OrderItem {
    uint256 price;
    /** why bytes: because struct too complex will be omitted */
    bytes data;
  }

  // An Order
  struct Order {
    /* salt, a random number */
    uint256 salt;
    /* address which create order */
    address user;
    /** ChainId explain which network */
    uint256 network;
    /** which intent, 1 for sell */
    uint256 intent;
    /** just 1 at v1 */
    uint256 delegateType;
    /** order end ddl */
    uint256 deadline;
    /**
      address of the ERC20 coin to trade
    */
    IERC20Upgradeable currency;
    /**
      items in an Order
    */
    OrderItem[] items;
    /**
      signature for Order, eip 2098 would be better
    */
    bytes32 r;
    bytes32 s;
    uint8 v;
    /**
      could be 1 now
    */
    uint8 signVersion;
  }

  struct Fee {
    uint256 percentage;
    address to;
  }

  struct SettleDetail {
    // order operation type
    Market.Op op;
    //
    uint256 orderIdx;
    //
    uint256 itemIdx;
    //
    uint256 price;
    //
    bytes32 itemHash;
    // delegate which address to transfer token
    IDelegate executionDelegate;
    Fee[] fees;
  }

  /**
   * @dev information from who send this tx
   */
  struct SettleShared {
    uint256 salt;
    uint256 deadline;
    uint256 amountToEth;
    address user;
    /**
     * can one order fail
     * if true, tx will revert if one order fail
     * else, tx didn't fail if one
     */
    bool canFail;
  }

  struct RunInput {
    // one Order match one SettleDetail
    Order[] orders;
    SettleDetail[] details;
    SettleShared shared;
  }

  enum InvStatus {
    NEW,
    COMPLETE,
    CANCELLED
  }

  /**
    Operation
  */
  enum Op {
    INVALID,
    COMPLETE_SELL_OFFER,
    COMPLETE_BUY_OFFER,
    CANCEL_OFFER
  }

  enum DelegationType {
    INVALID,
    ERC1155,
    ERC721
  }
}
