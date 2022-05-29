// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import '@openzeppelin/contracts/utils/Context.sol';

contract TwoStepOwnable is Context {
  address private _owner;
  address private _pendingOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _transferOwnership(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  function pendingOwner() public view virtual returns (address) {
    return _pendingOwner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), 'TSOwnable: caller not the owner');
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
   */
  function transferOwnership(address newOwner, bool direct) public virtual onlyOwner {
    require(newOwner != address(0), 'TSOwnable: new owner is zero');

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
    require(msg.sender == _pendingOwner, 'TSOwnable: caller != pending');

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
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferPendingOwnership(address newOwner) internal virtual {
    _pendingOwner = newOwner;
  }

  /**
   * @dev claim ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _claimOwnership() internal virtual {
    address oldOwner = _owner;
    emit OwnershipTransferred(oldOwner, _pendingOwner);

    _owner = _pendingOwner;
    _pendingOwner = address(0);
  }
}
