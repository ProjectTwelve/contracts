// SPDX-License-Identifier: GPL-3.0-only
// Refer to https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol and https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/OwnableUpgradeable.sol

pragma solidity 0.8.13;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable {
  address private _owner;
  address private _pendingOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  function __Ownable_init() internal onlyInitializing {
    __Ownable_init_unchained();
  }

  function __Ownable_init_unchained() internal onlyInitializing {
    _transferOwnership(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Return the address of the pending owner
   */
  function pendingOwner() public view virtual returns (address) {
    return _pendingOwner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), 'SafeOwnable: caller not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   * Note If direct is false, it will set an pending owner and the OwnerShipTransferring
   * only happens when the pending owner claim the ownership
   */
  function transferOwnership(address newOwner, bool direct) public virtual onlyOwner {
    require(newOwner != address(0), 'SafeOwnable: new owner is zero');
    if (direct) {
      _transferOwnership(newOwner);
    } else {
      _transferPendingOwnership(newOwner);
    }
  }

  /**
   * @dev pending owner call this function to claim ownership
   */
  function claimOwnership() public {
    require(msg.sender == _pendingOwner, 'SafeOwnable: caller != pending');

    _claimOwnership();
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @dev set the pending owner address
   * Internal function without access restriction.
   */
  function _transferPendingOwnership(address newOwner) internal virtual {
    _pendingOwner = newOwner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _claimOwnership() internal virtual {
    address oldOwner = _owner;
    emit OwnershipTransferred(oldOwner, _pendingOwner);

    _owner = _pendingOwner;
    _pendingOwner = address(0);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}
