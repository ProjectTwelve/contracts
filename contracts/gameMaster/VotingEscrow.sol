// SPDX-License-Identifier
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VotingEscrow is ReentrancyGuard {
   using SafeERC20 for IERC20;
  // all future times are rounded by week
  uint256  constant WEEK = 7 * 86400;
  // 4 years
  uint256 constant MAXTIME = 4 * 365 * 86400;
  uint256  constant MULTIPLIER = 10**18;

  address public p12Token;
  // total amount of locked P12token
  uint256 public totalLockedP12;
  mapping(address => LockedBalance) public locked;
  uint256 public epoch;

  mapping(uint256 =>Point) public pointHistory;
  mapping(address => mapping(uint256=>Point)) public userPointHistory;
  mapping(address => uint256) public userPointEpoch;
  mapping(uint256 => uint256) public slopeChanges;

  address public controller;
  bool public transfersEnabled;

  string public name;
  string public symbol;
  uint256 public decimals = 18;

  address public admin;
  address public futureAdmin;

  enum OperationType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME
  }

  event CommitOwnership(address admin);
  event ApplyOwnership(address admin);
  event Deposit(address indexed provider, uint256 value, uint256 indexed lockTime,OperationType t, uint256 ts);
  event Withdraw(address indexed provider, uint256 value, uint256 ts);
  event TotalLocked(uint256 prevTotalLockedP12, uint256 totalLockedP12);

  struct Point {
    uint256 bias;
    uint256 slope;
    uint256 ts;
    uint256 blk;
  }

  struct LockedBalance {
    uint256 amount;
    uint256 end;
  }

  struct CheckPointState {
      uint256 oldDslope;
      uint256 newDslope;
      uint256 _epoch;
  }

  /** 
    @notice Contract constructor
    @param P12TokenAddr `ERC20CRV` token address
    @param _name Token name
    @param _symbol Token symbol
  */
  constructor(
    address P12TokenAddr,
    string memory _name,
    string memory _symbol
  ) {
    name = _name;
    symbol = _symbol;
    admin = msg.sender;
    p12Token = P12TokenAddr;
    pointHistory[0].blk = block.number;
    pointHistory[0].ts = block.timestamp;
    controller = msg.sender;
    transfersEnabled = true;

  }

  /** 
    @notice Transfer ownership of VotingEscrow contract to `addr`
    @param _addr Address to have ownership transferred to
  */  
  function commitTransferOwnership(address _addr)external {
    require(msg.sender == admin,"VotingEscrow: caller must be admin");
    futureAdmin = _addr;
    emit CommitOwnership(_addr);
  }
  /** 
    @notice Apply ownership transfer
  */

  function applyTransferOwnership()external {
    require(msg.sender == admin,"VotingEscrow: caller must be admin");
    address _admin = futureAdmin;
    require(_admin != address(0),"VotingEscrow: admin address cannot be zero");
    admin = _admin;
    emit ApplyOwnership(_admin);

  }


  /** 
    @notice Get the most recently recorded rate of voting power decrease for `addr`
    @param _addr Address of the user wallet
    @return Value of the slope
  */

  function getLastUserSlope(address _addr)external view returns (uint256){
    uint256 uepoch = userPointEpoch[_addr];
    return userPointHistory[_addr][uepoch].slope;
  }

  /** 
    @notice Get the timestamp for checkpoint `_idx` for `_addr`
    @param _addr User wallet address
    @param _idx User epoch number
    @return Epoch time of the checkpoint
  */
  function userPointHistoryTs(address _addr,uint256 _idx)external view returns (uint256){
    return userPointHistory[_addr][_idx].ts;
  }

  /**
    @notice Get timestamp when `_addr`'s lock finishes
    @param _addr User wallet 
    @return Epoch time of the lock end
  */
  function lockedEnd(address _addr)external view returns (uint256){
     return locked[_addr].end;
  }
  /**
    @notice Record global and per-user data to checkpoint
    @param _addr User's wallet address. No user checkpoint if 0x0
    @param oldLocked Pevious locked amount / end lock time for the user
    @param newLocked New locked amount / end lock time for the user
  */
  
  function _checkPoint(address _addr,LockedBalance memory oldLocked,LockedBalance memory newLocked)internal {
    Point memory uOld ;
    Point memory uNew ;

    CheckPointState memory cpState;
    cpState.oldDslope = 0;
    cpState.newDslope = 0;
    cpState._epoch = epoch;

    if (_addr != address(0)){
      // Calculate slopes and biases
      // Kept at zero when they have to
      if(oldLocked.end > block.timestamp && oldLocked.amount>0){
        uOld.slope = oldLocked.amount / MAXTIME;
        uOld.bias = uOld.slope * (oldLocked.end - block.timestamp);
      }
      if(newLocked.end > block.timestamp && newLocked.amount >0){
        uNew.slope = newLocked.amount / MAXTIME;
        uNew.bias = uNew.slope*(newLocked.end -block.timestamp);
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
    Point memory lastPoint = Point(0,0,block.timestamp,block.number);
    if (cpState._epoch >0){
      lastPoint = pointHistory[cpState._epoch];
    }
    uint256 lastCheckPoint = lastPoint.ts;

    // initial_last_point is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract

    Point memory initialLastPoint = lastPoint;
    uint256 blockSlope = 0;
    if(block.timestamp > lastPoint.ts){
      blockSlope = MULTIPLIER * (block.number - lastPoint.blk)/(block.timestamp - lastPoint.ts);
    }
    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    uint256 ti = (lastCheckPoint /WEEK)* WEEK;
    for (uint24 i = 0; i < 255; i ++) {
      ti += WEEK;
      uint256 dSlope = 0;
      if (ti > block.timestamp) {
          ti = block.timestamp;
      } else {
          dSlope = slopeChanges[ti];
      }
      
      lastPoint.bias -= lastPoint.slope * uint256(ti - lastCheckPoint);
      lastPoint.slope += dSlope;
      if (lastPoint.bias < 0) {
          lastPoint.bias = 0;
      }
      if (lastPoint.slope < 0) {
          lastPoint.slope = 0;
      }
      lastCheckPoint = ti;
      lastPoint.ts = ti;
      lastPoint.blk = initialLastPoint.blk + blockSlope*(ti - initialLastPoint.ts)/MULTIPLIER;
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
    if (_addr != address(0)) {
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

    if (_addr != address(0)) {
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
      uint256 userEpoch = userPointEpoch[_addr] + 1;

      uNew.ts = block.timestamp;
      uNew.blk = block.number;
      userPointHistory[_addr][userEpoch] = uNew;
      userPointEpoch[_addr] = userEpoch;
    }
  }

  /**
    @notice Deposit and lock tokens for a user
    @param _addr User's wallet address
    @param _value Amount to deposit
    @param unlockTime New time when to unlock the tokens, or 0 if unchanged
    @param lockedBalance Previous locked amount / timestamp
  */

  function _depositFor(address _addr,uint256 _value,uint256 unlockTime,LockedBalance memory lockedBalance,OperationType t)internal{
    LockedBalance memory _locked = lockedBalance;
    uint256 totalLockedP12Before = totalLockedP12;
    totalLockedP12 = totalLockedP12Before + _value;
    LockedBalance memory oldLocked = _locked;
    // Adding to existing lock, or if a lock is expired - creating a new one
    _locked.amount += _value;
    if (unlockTime != 0){
      _locked.end = unlockTime;

    }
    locked[_addr] = _locked;

    // Possibilities:
    // Both old_locked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // _locked.end > block.timestamp (always)
    _checkPoint(_addr,oldLocked,_locked);
    if (_value !=0){
      IERC20(p12Token).transferFrom(_addr,address(this),_value);
    
    }
    emit Deposit(_addr,_value, _locked.end,t, block.timestamp);
    emit TotalLocked(totalLockedP12Before,totalLockedP12Before+_value);
  }

  
  /**
    @notice Record global data to checkpoint
  */
  function checkPoint()external{
    _checkPoint(address(0), LockedBalance({amount: 0, end: 0}), LockedBalance({amount: 0, end: 0}));
  }
  /**
    @notice Deposit `_value` tokens for `_addr` and add to the lock
    @dev Anyone (even a smart contract) can deposit for someone else, but
         cannot extend their locktime and deposit for a brand new user
    @param _addr User's wallet address
    @param _value Amount to add to user's lock  
  */
  function depositFor(address _addr,uint256 _value)external nonReentrant{
    LockedBalance memory _locked = locked[_addr];
    require(_value >0,"VotingEscrow: deposit value should > 0");
    require(_locked.amount > 0,"VotingEscrow: No existing lock found");
    require(_locked.end > block.timestamp,"VotingEscrow: Cannot add to expired lock. Withdraw");
    _depositFor(_addr,_value,0,locked[_addr],OperationType.DEPOSIT_FOR_TYPE);
  }

  /** 
    @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
    @param _value Amount to deposit
    @param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
  */
  function createLock(uint256 _value, uint256 _unlockTime) external nonReentrant {

    //Locktime is rounded down to weeks
    uint256 unlockTime = (_unlockTime / WEEK)* WEEK; 
    LockedBalance memory _locked = locked[msg.sender];
    require(_value >0,"VotingEscrow: deposit value should > 0");
    require(_locked.amount == 0,"VotingEscrow: Withdraw old tokens first");
    require(unlockTime > block.timestamp,"VotingEscrow: Can only lock until time in the future");
    require(unlockTime <= block.timestamp + MAXTIME,"VotingEscrow: Voting lock can be 4 years max");
    _depositFor(msg.sender,_value,unlockTime, _locked, OperationType.CREATE_LOCK_TYPE);
  }


  /**
    @notice Deposit `_value` additional tokens for `msg.sender`
            without modifying the unlock time
    @param _value Amount of tokens to deposit and add to the lock
  */
  function increaseAmount(uint256 _value)external nonReentrant {
    LockedBalance memory _locked = locked[msg.sender];
    require(_value > 0,"VotingEscrow: deposit value should > 0");
    require(_locked.amount >0, "VotingEscrow: No existing lock found");
    require(_locked.end > block.timestamp,"VotingEscrow: Cannot add to expired lock. Withdraw");
    _depositFor(msg.sender,_value,0, _locked, OperationType.INCREASE_LOCK_AMOUNT);
  }

  /** 
    @notice Extend the unlock time for `msg.sender` to `_unlock_time`
    @param _unlockTime New epoch time for unlocking
  */
  function increaseUnlockTime(uint256 _unlockTime)external nonReentrant{
    LockedBalance memory _locked = locked[msg.sender];
    uint256 unlockTime = (_unlockTime / WEEK)* WEEK;
    require(_locked.end >block.timestamp,"VotingEscrow: Lock expired");
    require(_locked.amount >0,"VotingEscrow: Nothing is locked");
    require(unlockTime > _locked.end ,"VotingEscrow: Can only increase lock duration");
    require(unlockTime <= block.timestamp + MAXTIME,"VotingEscrow: Voting lock can be 4 years max");
    _depositFor(msg.sender,0,unlockTime, _locked, OperationType.INCREASE_LOCK_AMOUNT);

  }


  /** 
    @notice Withdraw all tokens for `msg.sender`
    @dev Only possible if the lock has expired
  */
  function withdraw()external nonReentrant{
    LockedBalance memory _locked = locked[msg.sender];
    require(block.timestamp >= _locked.end,"VotingEscrow: The lock didn't expire");
    uint256 value = _locked.amount;

    LockedBalance memory oldLocked = _locked;
    _locked.end = 0;
    _locked.amount = 0;
    locked[msg.sender] = _locked;
    uint256 totalLockedP12Before = totalLockedP12;
    totalLockedP12 = totalLockedP12Before - value;

    // old_locked can have either expired <= timestamp or zero end
    // _locked has only 0 end
    // Both can have >= 0 amount

    _checkPoint(msg.sender,oldLocked,_locked);
    IERC20(p12Token).safeTransfer(msg.sender, value);

    emit Withdraw(msg.sender,value,block.timestamp);
    emit TotalLocked(totalLockedP12Before,totalLockedP12Before - value);

  }


  /** 
    @notice Binary search to estimate timestamp for block number
    @param _block Block to find
    @param max_epoch Don't go beyond this epoch
    @return Approximate timestamp for block
  */

  function findBlockEpoch(uint256 _block, uint256 max_epoch)internal view returns(uint256){
    uint256 _min = 0;
    uint256 _max = max_epoch;
    for (uint i = 0;i <= 128;i++){
      if (_min >= _max){
        break;
      }
      uint256 _mid = (_min + _max + 1)/2;
      if(pointHistory[_mid].blk<= _block){
        _min = _mid;
      }else{
        _max = _mid - 1;
      }
    }
    return _min;
  }
  /** 
    @notice Get the current voting power for `msg.sender`
    @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    @param _addr User wallet address
    @return User voting power
  */
  function balanceOf(address _addr)external  view returns (uint256){
    uint256 _epoch = userPointEpoch[_addr];
    if(_epoch ==0){
      return 0;
    }else{
      Point memory lastPoint = userPointHistory[_addr][_epoch];
      lastPoint.bias -= lastPoint.slope * (block.timestamp - lastPoint.ts);
      if(lastPoint.bias < 0){
        lastPoint.bias = 0;
      }
      return lastPoint.bias;
    }
  }

  /** 
    @notice Measure voting power of `addr` at block height `_block`
    @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    @param _addr User's wallet address
    @param _block Block to calculate the voting power at
    @return Voting power
  */
  function balanceOfAt(address _addr,uint256 _block) external view returns (uint256){
    require(_block <= block.number,"VotingEscrow: input block number must be <= current block number");
    // Binary search
    uint256 _min = 0;
    uint256 _max = userPointEpoch[_addr];
    for (uint i=1;i<=128;i++){
      if (_min >= _max){
        break ;
      }
      uint256 _mid = (_min + _max +1)/2;
      if(userPointHistory[_addr][_mid].blk <= _block){
        _min = _mid;
      }else{
        _max = _mid -1;
      }
    }
    Point memory uPoint = userPointHistory[_addr][_min];
    uint256 maxEpoch = epoch;
    uint256 _epoch = findBlockEpoch(_block,maxEpoch);
    Point memory point0 = pointHistory[_epoch];
    uint256 dBlock = 0;
    uint256 dt = 0;
    if (_epoch < maxEpoch){
      Point memory point1 = pointHistory[_epoch +1];
      dBlock = point1.blk - point0.blk;
      dt = point1.ts - point0.ts;
    }else{
      dBlock = block.number - point0.blk;
      dt = block.timestamp - point0.ts;
    }
    uint256 blockTime = point0.ts;
    if (dBlock !=0){
      blockTime += dt*(_block-point0.blk)/dBlock;
    }
    uPoint.bias -= uPoint.slope * (blockTime - uPoint.ts);
    if(uPoint.bias >= 0){
      return uPoint.bias;
    }else{
      return 0;
    }
  }

  /** 
    @notice Calculate total voting power at some point in the past
    @param point The point (bias/slope) to start search from
    @param t Time to calculate the total voting power at
    @return Total voting power at that time
  */  
  function supplyAt(Point memory point,uint256 t)internal view returns (uint256){
    Point memory lastPoint = point;
    uint256 ti = (lastPoint.ts / WEEK) * WEEK;
    for (uint24 i = 0; i < 255; i ++) {
        ti += WEEK;
        uint256 dSlope = 0;
        if (ti > t) {
            ti = t;
        } else {
            dSlope = slopeChanges[ti];
        }
        lastPoint.bias -= lastPoint.slope * uint256(ti - lastPoint.ts);
        if (ti == t) {
            break;
        }
        lastPoint.slope += dSlope;
        lastPoint.ts = ti;
    }
    if(lastPoint.bias < 0){
      lastPoint.bias = 0;
    }
    return uint256(lastPoint.bias);
  }
  /**
   
    @notice Calculate total voting power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total voting power
  
  */

  function totalSupply()external returns (uint256){
    uint256 _epoch = epoch;
    Point memory lastPoint = pointHistory[_epoch];
    return supplyAt(lastPoint,block.timestamp);
  }

  /** 
    @notice Calculate total voting power at some point in the past
    @param _block Block to calculate the total voting power at
    @return Total voting power at `_block`
  */
  function totalSupplyAt(uint256 _block) external view returns(uint256){
    require(_block <= block.number,"VotingEscrow: block number must be <= block number");
    uint256 _epoch = epoch;
    uint256 targetEpoch = findBlockEpoch(_block,_epoch);

    Point memory point = pointHistory[targetEpoch];
    uint256 dt = 0;
    if (targetEpoch < _epoch){
      Point memory pointNext = pointHistory[targetEpoch+1];
      if (point.blk != pointNext.blk){
        dt = (_block- point.blk)*(pointNext.ts-point.ts)/(pointNext.blk - point.blk);

      }
    }else{
       if (point.blk != block.number){
         dt = (_block - point.blk) *(block.timestamp - point.ts)/(block.number - point.blk);
       }
    }
    // Now dt contains info on how far are we beyond point
    return supplyAt(point,point.ts+dt);
  }



  // Dummy methods for compatibility with Aragon
  function changeController(address _newController)external {
    require(msg.sender == controller,"VotingEscrow: caller must be controller");
    controller = _newController;
  }
}
