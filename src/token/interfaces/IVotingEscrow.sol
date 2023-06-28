// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.19;

interface IVotingEscrow {

  error InValidBlockNumber();

  error InvalidValue();
  // user have not lock token before
  error NoExistedLock();
  // user have locked token
  error LockExisted();
  // lock created before is expired, cannot increase amount or time
  error LockExpired();
  // lock time set is too short
  error LockTimeTooShort();
  // lock time set is too long
  error LockTimeTooLong();
  // contract is stopped in case of emergency
  error ContractStopped();
  // withdraw conditions are not met
  error CannotWithdraw();

  function getLastUserSlope(address addr) external returns (int256);

  function lockedEnd(address addr) external returns (uint256);
}
