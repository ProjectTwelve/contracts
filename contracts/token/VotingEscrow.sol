// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import '../access/SafeOwnable.sol';
import './interfaces/IVotingEscrow.sol';

contract VotingEscrow is ReentrancyGuard, SafeOwnable, Pausable, IVotingEscrow {
  using SafeERC20 for IERC20;
  // all future times are rounded by week
  uint256 constant WEEK = 7 * 86400;
  // 4 years
  uint256 constant MAXTIME = 4 * 365 * 86400;
  uint256 constant MULTIPLIER = 10**18;

  address public p12Token;
  // total amount of locked P12token
  uint256 public totalLockedP12;
  mapping(address => LockedBalance) public locked;
  uint256 public epoch;
  bool public expired; // true if the contract end

  mapping(uint256 => Point) public pointHistory;
  mapping(address => mapping(uint256 => Point)) public userPointHistory;
  mapping(address => uint256) public userPointEpoch;
  mapping(uint256 => int256) public slopeChanges;

  string public name;
  string public symbol;
  uint256 public decimals = 18;

  enum OperationType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME
  }

  event CommitOwnership(address admin);
  event ApplyOwnership(address admin);
  event Deposit(address indexed provider, uint256 value, uint256 indexed lockTime, OperationType t, uint256 ts);
  event Withdraw(address indexed provider, uint256 value, uint256 ts);
  event TotalLocked(uint256 prevTotalLockedP12, uint256 totalLockedP12);

  struct Point {
    int256 bias;
    int256 slope;
    uint256 ts;
    uint256 blk;
  }

  struct LockedBalance {
    int256 amount;
    uint256 end;
  }

  struct CheckPointState {
    int256 oldDslope;
    int256 newDslope;
    uint256 _epoch;
  }

  /** 
    @notice Contract constructor
    @param P12TokenAddr `ERC20CRV` token address
    @param name_ Token name
    @param symbol_ Token symbol
  */
  constructor(
    address P12TokenAddr,
    string memory name_,
    string memory symbol_
  ) {
    name = name_;
    symbol = symbol_;
    p12Token = P12TokenAddr;
    pointHistory[0].blk = block.number;
    pointHistory[0].ts = block.timestamp;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  modifier contractNotExpired() {
    require(!expired, 'VotingEscrow: The contract has been stopped, only withdrawals can be made');
    _;
  }

  function expire() external onlyOwner contractNotExpired {
    expired = true;
    emit Expired(msg.sender, block.timestamp);
  }

  /** 
    @notice Get the most recently recorded rate of voting power decrease for `addr`
    @param addr Address of the user wallet
    @return Value of the slope
  */

  function getLastUserSlope(address addr) external view returns (int256) {
    uint256 uEpoch = userPointEpoch[addr];
    return userPointHistory[addr][uEpoch].slope;
  }

  /** 
    @notice Get the timestamp for checkpoint `idx` for `addr`
    @param addr User wallet address
    @param idx User epoch number
    @return Epoch time of the checkpoint
  */
  function userPointHistoryTs(address addr, uint256 idx) external view returns (uint256) {
    return userPointHistory[addr][idx].ts;
  }

  /**
    @notice Get timestamp when `addr`'s lock finishes
    @param addr User wallet 
    @return Epoch time of the lock end
  */
  function lockedEnd(address addr) external view returns (uint256) {
    return locked[addr].end;
  }

  /**
    @notice Record global and per-user data to checkpoint
    @param addr User's wallet address. No user checkpoint if 0x0
    @param oldLocked Previous locked amount / end lock time for the user
    @param newLocked New locked amount / end lock time for the user
  */

  function _checkPoint(
    address addr,
    LockedBalance memory oldLocked,
    LockedBalance memory newLocked
  ) internal {
    Point memory uOld;
    Point memory uNew;

    CheckPointState memory cpState;
    cpState.oldDslope = 0;
    cpState.newDslope = 0;
    cpState._epoch = epoch;
    if (addr != address(0)) {
      // Calculate slopes and biases
      // Kept at zero when they have to
      if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
        uOld.slope = oldLocked.amount / int256(MAXTIME);
        uOld.bias = uOld.slope * int256(oldLocked.end - block.timestamp);
      }
      if (newLocked.end > block.timestamp && newLocked.amount > 0) {
        uNew.slope = newLocked.amount / int256(MAXTIME);
        uNew.bias = uNew.slope * int256(newLocked.end - block.timestamp);
      }
      // Read values of scheduled changes in the slope
      // old_locked.end can be in the past and in the future
      // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros

      cpState.oldDslope = slopeChanges[oldLocked.end];
      if (newLocked.end != 0) {
        if (newLocked.end == oldLocked.end) {
          cpState.newDslope = cpState.oldDslope;
        } else {
          cpState.newDslope = slopeChanges[newLocked.end];
        }
      }
    }
    Point memory lastPoint = Point(0, 0, block.timestamp, block.number);
    if (cpState._epoch > 0) {
      lastPoint = pointHistory[cpState._epoch];
    }
    uint256 lastCheckPoint = lastPoint.ts;
    // initial_last_point is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract

    Point memory initialLastPoint = lastPoint;
    uint256 blockSlope = 0;
    if (block.timestamp > lastPoint.ts) {
      blockSlope = (MULTIPLIER * (block.number - lastPoint.blk)) / (block.timestamp - lastPoint.ts);
    }
    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    uint256 ti = (lastCheckPoint / WEEK) * WEEK;

    for (uint24 i = 0; i < 255; i++) {
      ti += WEEK;
      int256 dSlope = 0;
      if (ti > block.timestamp) {
        ti = block.timestamp;
      } else {
        dSlope = slopeChanges[ti];
      }

      lastPoint.bias -= lastPoint.slope * int256(ti - lastCheckPoint);
      lastPoint.slope += dSlope;
      if (lastPoint.bias < 0) {
        lastPoint.bias = 0;
      }
      if (lastPoint.slope < 0) {
        lastPoint.slope = 0;
      }
      lastCheckPoint = ti;
      lastPoint.ts = ti;
      lastPoint.blk = initialLastPoint.blk + (blockSlope * (ti - initialLastPoint.ts)) / MULTIPLIER;
      cpState._epoch += 1;
      if (ti == block.timestamp) {
        lastPoint.blk = block.number;
        break;
      } else {
        pointHistory[cpState._epoch] = lastPoint;
      }
    }
    epoch = cpState._epoch;
    // Now point_history is filled until t=now
    if (addr != address(0)) {
      // CalculateIf last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)

      lastPoint.slope += (uNew.slope - uOld.slope);
      lastPoint.bias += (uNew.bias - uOld.bias);
      if (lastPoint.slope < 0) {
        lastPoint.slope = 0;
      }
      if (lastPoint.bias < 0) {
        lastPoint.bias = 0;
      }
    }
    // Record the changed point into history
    pointHistory[cpState._epoch] = lastPoint;
    if (addr != address(0)) {
      // Schedule the slope changes (slope is going down)
      // We subtract new_user_slope from [new_locked.end]
      // and add old_user_slope to [old_locked.end]
      if (oldLocked.end > block.timestamp) {
        cpState.oldDslope += uOld.slope;
        if (newLocked.end == oldLocked.end) {
          cpState.oldDslope -= uNew.slope;
        }
        slopeChanges[oldLocked.end] = cpState.oldDslope;
      }
      if (newLocked.end > block.timestamp) {
        if (newLocked.end > oldLocked.end) {
          cpState.newDslope -= uNew.slope;
          slopeChanges[newLocked.end] = cpState.newDslope;
        }
      }

      // Now handle user history
      uint256 userEpoch = userPointEpoch[addr] + 1;
      userPointEpoch[addr] = userEpoch;
      uNew.ts = block.timestamp;
      uNew.blk = block.number;
      userPointHistory[addr][userEpoch] = uNew;
    }
  }

  /**
    @notice Deposit and lock tokens for a user
    @param addr User's wallet address
    @param value Amount to deposit
    @param unlockTime New time when to unlock the tokens, or 0 if unchanged
    @param lockedBalance Previous locked amount / timestamp
  */

  function _depositFor(
    address addr,
    uint256 value,
    uint256 unlockTime,
    LockedBalance memory lockedBalance,
    OperationType t
  ) internal {
    LockedBalance memory _locked = lockedBalance;
    uint256 totalLockedP12Before = totalLockedP12;
    totalLockedP12 = totalLockedP12Before + value;
    LockedBalance memory oldLocked = LockedBalance({ amount: _locked.amount, end: _locked.end });
    // Adding to existing lock, or if a lock is expired - creating a new one
    _locked.amount += int256(value);
    if (unlockTime != 0) {
      _locked.end = unlockTime;
    }
    locked[addr] = _locked;
    // Possibilities:
    // Both old_locked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // _locked.end > block.timestamp (always)

    _checkPoint(addr, oldLocked, _locked);
    if (value != 0) {
      IERC20(p12Token).transferFrom(addr, address(this), value);
    }
    emit Deposit(addr, value, _locked.end, t, block.timestamp);
    emit TotalLocked(totalLockedP12Before, totalLockedP12Before + value);
  }

  /**
    @notice Record global data to checkpoint
  */
  function checkPoint() external {
    _checkPoint(address(0), LockedBalance({ amount: 0, end: 0 }), LockedBalance({ amount: 0, end: 0 }));
  }

  /**
    @notice Deposit `value` tokens for `addr` and add to the lock
    @dev Anyone (even a smart contract) can deposit for someone else, but
         cannot extend their lockTime and deposit for a brand new user
    @param addr User's wallet address
    @param value Amount to add to user's lock  
  */
  function depositFor(address addr, uint256 value) external nonReentrant whenNotPaused contractNotExpired {
    LockedBalance memory _locked = locked[addr];
    require(value > 0, 'VotingEscrow: deposit value should > 0');
    require(_locked.amount > 0, 'VotingEscrow: No existing lock found');
    require(_locked.end > block.timestamp, 'VotingEscrow: Cannot add to expired lock. Withdraw');
    _depositFor(addr, value, 0, locked[addr], OperationType.DEPOSIT_FOR_TYPE);
  }

  /** 
    @notice Deposit `value` tokens for `msg.sender` and lock until `unlock_time`
    @param value Amount to deposit
    @param unlockTime Epoch time when tokens unlock, rounded down to whole weeks
  */
  function createLock(uint256 value, uint256 unlockTime) external nonReentrant whenNotPaused contractNotExpired {
    //lockTime is rounded down to weeks
    uint256 _unlockTime = (unlockTime / WEEK) * WEEK;
    LockedBalance memory _locked = locked[msg.sender];
    require(value > 0, 'VotingEscrow: deposit value should > 0');
    require(_locked.amount == 0, 'VotingEscrow: Withdraw old tokens first');
    require(_unlockTime > block.timestamp, 'VotingEscrow: Can only lock until time in the future');
    require(_unlockTime <= block.timestamp + MAXTIME, 'VotingEscrow: Voting lock can be 4 years max');
    _depositFor(msg.sender, value, _unlockTime, _locked, OperationType.CREATE_LOCK_TYPE);
  }

  /**
    @notice Deposit `value` additional tokens for `msg.sender`
            without modifying the unlock time
    @param value Amount of tokens to deposit and add to the lock
  */
  function increaseAmount(uint256 value) external nonReentrant whenNotPaused contractNotExpired {
    LockedBalance memory _locked = locked[msg.sender];
    require(value > 0, 'VotingEscrow: deposit value should > 0');
    require(_locked.amount > 0, 'VotingEscrow: No existing lock found');
    require(_locked.end > block.timestamp, 'VotingEscrow: Cannot add to expired lock. Withdraw');
    _depositFor(msg.sender, value, 0, _locked, OperationType.INCREASE_LOCK_AMOUNT);
  }

  /** 
    @notice Extend the unlock time for `msg.sender` to `unlock_time`
    @param unlockTime New epoch time for unlocking
  */
  function increaseUnlockTime(uint256 unlockTime) external nonReentrant whenNotPaused contractNotExpired {
    LockedBalance memory _locked = locked[msg.sender];
    uint256 _unlockTime = (unlockTime / WEEK) * WEEK;
    require(_locked.end > block.timestamp, 'VotingEscrow: Lock expired');
    require(_locked.amount > 0, 'VotingEscrow: Nothing is locked');
    require(_unlockTime > _locked.end, 'VotingEscrow: Can only increase lock duration');
    require(_unlockTime <= block.timestamp + MAXTIME, 'VotingEscrow: Voting lock can be 4 years max');
    _depositFor(msg.sender, 0, _unlockTime, _locked, OperationType.INCREASE_LOCK_AMOUNT);
  }

  /** 
    @notice Withdraw all tokens for `msg.sender`
    @dev Only possible if the lock has expired
  */
  function withdraw() external nonReentrant {
    LockedBalance memory _locked = locked[msg.sender];
    require(_locked.amount > 0, 'VotingEscrow: you have not pledged');
    require(block.timestamp >= _locked.end, 'VotingEscrow: The lock did not expire');
    uint256 value = uint256(_locked.amount);

    LockedBalance memory oldLocked = _locked;
    _locked.end = 0;
    _locked.amount = 0;
    locked[msg.sender] = _locked;
    uint256 totalLockedP12Before = totalLockedP12;
    totalLockedP12 = totalLockedP12Before - value;

    // old_locked can have either expired <= timestamp or zero end
    // _locked has only 0 end
    // Both can have >= 0 amount

    _checkPoint(msg.sender, oldLocked, _locked);
    IERC20(p12Token).safeTransfer(msg.sender, value);

    emit Withdraw(msg.sender, value, block.timestamp);
    emit TotalLocked(totalLockedP12Before, totalLockedP12Before - value);
  }

  /** 
    @notice Binary search to estimate timestamp for block number
    @param blk Block to find
    @param maxEpoch Don't go beyond this epoch
    @return Approximate timestamp for block
  */

  function findBlockEpoch(uint256 blk, uint256 maxEpoch) public view returns (uint256) {
    uint256 _min = 0;
    uint256 _max = maxEpoch;
    for (uint256 i = 0; i <= 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (pointHistory[_mid].blk <= blk) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  /** 
    @notice Get the current voting power for `msg.sender`
    @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    @param addr User wallet address
    @return User voting power
  */
  function balanceOf(address addr) external view returns (int256) {
    uint256 _epoch = userPointEpoch[addr];
    if (_epoch == 0) {
      return 0;
    } else {
      Point memory lastPoint = userPointHistory[addr][_epoch];
      lastPoint.bias -= lastPoint.slope * int256(block.timestamp - lastPoint.ts);
      if (lastPoint.bias < 0) {
        lastPoint.bias = 0;
      }
      return lastPoint.bias;
    }
  }

  /** 
    @notice Measure voting power of `addr` at block height `_block`
    @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    @param addr User's wallet address
    @param blk Block to calculate the voting power at
    @return Voting power
  */
  function balanceOfAt(address addr, uint256 blk) external view returns (int256) {
    require(blk <= block.number, 'VotingEscrow: input block number must be <= current block number');
    // Binary search
    uint256 _min = 0;
    uint256 _max = userPointEpoch[addr];
    for (uint256 i = 1; i <= 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (userPointHistory[addr][_mid].blk <= blk) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    Point memory uPoint = userPointHistory[addr][_min];
    uint256 maxEpoch = epoch;
    uint256 _epoch = findBlockEpoch(blk, maxEpoch);
    Point memory point0 = pointHistory[_epoch];
    uint256 dBlock = 0;
    uint256 dt = 0;
    if (_epoch < maxEpoch) {
      Point memory point1 = pointHistory[_epoch + 1];
      dBlock = point1.blk - point0.blk;
      dt = point1.ts - point0.ts;
    } else {
      dBlock = block.number - point0.blk;
      dt = block.timestamp - point0.ts;
    }
    uint256 blockTime = point0.ts;
    if (dBlock != 0) {
      blockTime += (dt * (blk - point0.blk)) / dBlock;
    }
    uPoint.bias -= uPoint.slope * int256(blockTime - uPoint.ts);
    if (uPoint.bias >= 0) {
      return uPoint.bias;
    } else {
      return 0;
    }
  }

  /** 
    @notice Calculate total voting power at some point in the past
    @param point The point (bias/slope) to start search from
    @param t Time to calculate the total voting power at
    @return Total voting power at that time
  */
  function supplyAt(Point memory point, uint256 t) internal view returns (uint256) {
    Point memory lastPoint = point;
    uint256 ti = (lastPoint.ts / WEEK) * WEEK;
    for (uint24 i = 0; i < 255; i++) {
      ti += WEEK;
      int256 dSlope = 0;
      if (ti > t) {
        ti = t;
      } else {
        dSlope = slopeChanges[ti];
      }
      lastPoint.bias -= lastPoint.slope * int256(ti - lastPoint.ts);
      if (ti == t) {
        break;
      }
      lastPoint.slope += dSlope;
      lastPoint.ts = ti;
    }
    if (lastPoint.bias < 0) {
      lastPoint.bias = 0;
    }
    return uint256(lastPoint.bias);
  }

  /**
   
    @notice Calculate total voting power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total voting power
  
  */

  function totalSupply() external view returns (uint256) {
    uint256 _epoch = epoch;
    Point memory lastPoint = pointHistory[_epoch];
    return supplyAt(lastPoint, block.timestamp);
  }

  /** 
    @notice Calculate total voting power at some point in the past
    @param blk Block to calculate the total voting power at
    @return Total voting power at `_block`
  */
  function totalSupplyAt(uint256 blk) external view returns (uint256) {
    require(blk <= block.number, 'VotingEscrow: block number must be <= block number');
    uint256 _epoch = epoch;
    uint256 targetEpoch = findBlockEpoch(blk, _epoch);

    Point memory point = pointHistory[targetEpoch];
    uint256 dt = 0;
    if (targetEpoch < _epoch) {
      Point memory pointNext = pointHistory[targetEpoch + 1];
      if (point.blk != pointNext.blk) {
        dt = ((blk - point.blk) * (pointNext.ts - point.ts)) / (pointNext.blk - point.blk);
      }
    } else {
      if (point.blk != block.number) {
        dt = ((blk - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
      }
    }
    // Now dt contains info on how far are we beyond point
    return supplyAt(point, point.ts + dt);
  }
}
