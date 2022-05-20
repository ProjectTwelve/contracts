// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './MarketConsts.sol';
import './interfaces/IDelegate.sol';

contract ERC721Delegate is IDelegate, AccessControl, IERC721Receiver, ReentrancyGuard, Pausable {
  bytes32 public constant DELEGATION_CALLER = keccak256('DELEGATION_CALLER');
  bytes32 public constant PAUSABLE_CALLER = keccak256('PAUSABLE_CALLER');

  /**
   * @dev single item data
   */
  struct Pair {
    uint256 salt;
    IERC721 token;
    uint256 tokenId;
  }

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function pause() public onlyRole(PAUSABLE_CALLER) {
    _pause();
  }

  function unpause() public onlyRole(PAUSABLE_CALLER) {
    _unpause();
  }

  /**
   * @dev Received function
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
   * @dev decode data to the array of Pair
   */
  function decode(bytes calldata data) public pure returns (Pair[] memory) {
    return abi.decode(data, (Pair[]));
  }

  /**
   * @return delegateType the delegate's type
   */
  function delegateType() external pure override returns (uint256) {
    return uint256(Market.DelegationType.ERC721);
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
      p.token.safeTransferFrom(seller, buyer, p.tokenId);
    }
    return true;
  }
}
