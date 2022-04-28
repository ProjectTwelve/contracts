// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './MarketConsts.sol';
import './interface/IDelegate.sol';
import '../libraries/Utils.sol';

contract ERC1155Delegate is IDelegate, AccessControl, IERC1155Receiver, ReentrancyGuard {
  bytes32 public constant DELEGATION_CALLER = keccak256('DELEGATION_CALLER');

  /**
   * @dev single item data  Pair[1]
   */
  struct Pair {
    IERC1155 token;
    uint256 tokenId;
    uint256 amount;
    uint256 salt;
  }

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function decode(bytes calldata data) public pure returns (Pair[] memory) {
    return abi.decode(data, (Pair[]));
  }

  function delegateType() external pure override returns (uint256) {
    // return uint256(Market.DelegationType.ERC1155);
    return 1;
  }

  function executeSell(
    address seller,
    address buyer,
    bytes calldata data
  ) public override nonReentrant onlyRole(DELEGATION_CALLER) returns (bool) {
    // TODO: no need for loop, just transferBatch
    Pair[] memory pairs = decode(data);
    for (uint256 i = 0; i < pairs.length; i++) {
      Pair memory p = pairs[i];
      p.token.safeBatchTransferFrom(
        seller,
        buyer,
        Utils._asSingletonArray(p.tokenId),
        Utils._asSingletonArray(p.amount),
        new bytes(1)
      );
    }
    return true;
  }

  // function executeBuy(
  //   address seller,
  //   address buyer,
  //   bytes calldata data
  // ) public override onlyRole(DELEGATION_CALLER) returns (bool) {
  //   // Pair[] memory pairs = decode(data);
  //   // for (uint256 i = 0; i < pairs.length; i++) {
  //   //     Pair memory p = pairs[i];
  //   //     p.token.safeTransferFrom(seller, buyer, p.tokenId);
  //   // }
  //   return true;
  // }

  // function executeBid(
  //   address seller,
  //   address previousBidder,
  //   address, // bidder,
  //   bytes calldata data
  // ) public override onlyRole(DELEGATION_CALLER) returns (bool) {
  //   // if (previousBidder == address(0)) {
  //   //     Pair[] memory pairs = decode(data);
  //   //     for (uint256 i = 0; i < pairs.length; i++) {
  //   //         Pair memory p = pairs[i];
  //   //         p.token.safeTransferFrom(seller, address(this), p.tokenId);
  //   //     }
  //   // }
  //   return true;
  // }

  // function executeAuctionComplete(
  //   address, // seller,
  //   address buyer,
  //   bytes calldata data
  // ) public override onlyRole(DELEGATION_CALLER) returns (bool) {
  //   // Pair[] memory pairs = decode(data);
  //   // for (uint256 i = 0; i < pairs.length; i++) {
  //   //     Pair memory p = pairs[i];
  //   //     p.token.safeTransferFrom(address(this), buyer, p.tokenId);
  //   // }
  //   return true;
  // }

  // function executeAuctionRefund(
  //   address seller,
  //   address, // lastBidder,
  //   bytes calldata data
  // ) public override onlyRole(DELEGATION_CALLER) returns (bool) {
  //   // Pair[] memory pairs = decode(data);
  //   // for (uint256 i = 0; i < pairs.length; i++) {
  //   //     Pair memory p = pairs[i];
  //   //     p.token.safeTransferFrom(address(this), seller, p.tokenId);
  //   // }
  //   return true;
  // }

  // function transferBatch(Pair[] memory pairs, address to) public {
  //     for (uint256 i = 0; i < pairs.length; i++) {
  //         Pair memory p = pairs[i];
  //         p.token.safeTransferFrom(msg.sender, to, p.tokenId);
  //     }
  // }
}
