// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './MarketConsts.sol';
import './interfaces/IDelegate.sol';

contract ERC1155Delegate is IDelegate, AccessControl, IERC1155Receiver, ReentrancyGuard, Pausable {
  bytes32 public constant DELEGATION_CALLER = keccak256('DELEGATION_CALLER');
  bytes32 public constant PAUSABLE_CALLER = keccak256('PAUSABLE_CALLER');

  /**
   * @dev single item data
   */
  struct Pair {
    uint256 salt;
    IERC1155 token;
    uint256 tokenId;
    uint256 amount;
  }



  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /**
   * @return delegateType the delegate's type
   */
  function delegateType() external pure override returns (uint256) {
    return uint256(Market.DelegationType.ERC1155);
  }

  /**
   * @dev Received function
   */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  /**
   * @dev Received function
   */
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC1155Received.selector;
  }


  function pause() public onlyRole(PAUSABLE_CALLER) {
    _pause();
  }

  function unpause() public onlyRole(PAUSABLE_CALLER) {
    _unpause();
  }

  
  

  /**
   * @dev decode data to the array of Pair
   */
  function decode(bytes calldata data) public pure returns (Pair[] memory) {
    return abi.decode(data, (Pair[]));
  }

  

  /**
   * @dev run the sell to transfer item
   * @param seller address which sell the item
   * @param buyer address which buy the item
   * @param data the item's data, which will be decode as a array of Pair
   */
  function executeSell(
    address seller,
    address buyer,
    bytes calldata data
  ) public override nonReentrant onlyRole(DELEGATION_CALLER) whenNotPaused returns (bool) {
    Pair[] memory pairs = decode(data);
    for (uint256 i = 0; i < pairs.length; i++) {
      Pair memory p = pairs[i];
      p.token.safeTransferFrom(seller, buyer, p.tokenId, p.amount, new bytes(0));
    }
    return true;
  }
}
