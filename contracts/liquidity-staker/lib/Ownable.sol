pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 *
 * @notice Ownership related functions
 */
contract Ownable {
  address public _OWNER_;
  address public _NEW_OWNER_;

  // ============ Events ============

  event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // ============ Modifiers ============

  modifier onlyOwner() {
    require(msg.sender == _OWNER_, 'NOT_OWNER');
    _;
  }

  // ============ Functions ============

  constructor() {
    _OWNER_ = msg.sender;
    emit OwnershipTransferred(address(0), _OWNER_);
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), 'INVALID_OWNER');
    emit OwnershipTransferPrepared(_OWNER_, newOwner);
    _NEW_OWNER_ = newOwner;
  }

  function claimOwnership() external {
    require(msg.sender == _NEW_OWNER_, 'INVALID_CLAIM');
    emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
    _OWNER_ = _NEW_OWNER_;
    _NEW_OWNER_ = address(0);
  }
}
