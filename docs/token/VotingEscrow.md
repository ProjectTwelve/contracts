## VotingEscrow

### WEEK

```solidity
uint256 WEEK
```

### MAXTIME

```solidity
uint256 MAXTIME
```

### MULTIPLIER

```solidity
uint256 MULTIPLIER
```

### p12Token

```solidity
address p12Token
```

### totalLockedP12

```solidity
uint256 totalLockedP12
```

### locked

```solidity
mapping(address => struct VotingEscrow.LockedBalance) locked
```

### epoch

```solidity
uint256 epoch
```

### expired

```solidity
bool expired
```

### pointHistory

```solidity
mapping(uint256 => struct VotingEscrow.Point) pointHistory
```

### userPointHistory

```solidity
mapping(address => mapping(uint256 => struct VotingEscrow.Point)) userPointHistory
```

### userPointEpoch

```solidity
mapping(address => uint256) userPointEpoch
```

### slopeChanges

```solidity
mapping(uint256 => int256) slopeChanges
```

### name

```solidity
string name
```

### symbol

```solidity
string symbol
```

### decimals

```solidity
uint256 decimals
```

### OperationType

```solidity
enum OperationType {
  DEPOSIT_FOR_TYPE,
  CREATE_LOCK_TYPE,
  INCREASE_LOCK_AMOUNT,
  INCREASE_UNLOCK_TIME
}
```

### Expired

```solidity
event Expired(address addr, uint256 timestamp)
```

### Deposit

```solidity
event Deposit(address provider, uint256 value, uint256 lockTime, enum VotingEscrow.OperationType t, uint256 ts)
```

### Withdraw

```solidity
event Withdraw(address provider, uint256 value, uint256 ts)
```

### TotalLocked

```solidity
event TotalLocked(uint256 prevTotalLockedP12, uint256 totalLockedP12)
```

### Point

```solidity
struct Point {
  int256 bias;
  int256 slope;
  uint256 ts;
  uint256 blk;
}
```

### LockedBalance

```solidity
struct LockedBalance {
  int256 amount;
  uint256 end;
}
```

### CheckPointState

```solidity
struct CheckPointState {
  int256 oldDslope;
  int256 newDslope;
  uint256 _epoch;
}
```

### constructor

```solidity
constructor(address p12TokenAddr_, string name_, string symbol_) public
```

Contract constructor
    @param p12TokenAddr_ `ERC20P12` token address
    @param name_ Token name
    @param symbol_ Token symbol

### expire

```solidity
function expire() external
```

### getLastUserSlope

```solidity
function getLastUserSlope(address addr) external view returns (int256)
```

Get the most recently recorded rate of voting power decrease for `addr`
    @param addr Address of the user wallet
    @return Value of the slope

### userPointHistoryTs

```solidity
function userPointHistoryTs(address addr, uint256 idx) external view returns (uint256)
```

Get the timestamp for checkpoint `idx` for `addr`
    @param addr User wallet address
    @param idx User epoch number
    @return Epoch time of the checkpoint

### lockedEnd

```solidity
function lockedEnd(address addr) external view returns (uint256)
```

Get timestamp when `addr`'s lock finishes
    @param addr User wallet 
    @return Epoch time of the lock end

### checkPoint

```solidity
function checkPoint() external
```

Record global data to checkpoint

### depositFor

```solidity
function depositFor(address addr, uint256 value) external
```

Deposit `value` tokens for `addr` and add to the lock
    @dev Anyone (even a smart contract) can deposit for someone else, but
         cannot extend their lockTime and deposit for a brand new user
    @param addr User's wallet address
    @param value Amount to add to user's lock

### createLock

```solidity
function createLock(uint256 value, uint256 unlockTime) external
```

Deposit `value` tokens for `msg.sender` and lock until `unlock_time`
    @param value Amount to deposit
    @param unlockTime Epoch time when tokens unlock, rounded down to whole weeks

### increaseAmount

```solidity
function increaseAmount(uint256 value) external
```

Deposit `value` additional tokens for `msg.sender`
            without modifying the unlock time
    @param value Amount of tokens to deposit and add to the lock

### increaseUnlockTime

```solidity
function increaseUnlockTime(uint256 unlockTime) external
```

Extend the unlock time for `msg.sender` to `unlock_time`
    @param unlockTime New epoch time for unlocking

### withdraw

```solidity
function withdraw() external
```

Withdraw all tokens for `msg.sender`
    @dev Only possible if the lock has expired or contract expired

### balanceOf

```solidity
function balanceOf(address addr) external view returns (int256)
```

Get the current voting power for `msg.sender`
    @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    @param addr User wallet address
    @return User voting power

### balanceOfAt

```solidity
function balanceOfAt(address addr, uint256 blk) external view returns (int256)
```

Measure voting power of `addr` at block height `_block`
    @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    @param addr User's wallet address
    @param blk Block to calculate the voting power at
    @return Voting power

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

Calculate total voting power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total voting power

### totalSupplyAt

```solidity
function totalSupplyAt(uint256 blk) external view returns (uint256)
```

Calculate total voting power at some point in the past
    @param blk Block to calculate the total voting power at
    @return Total voting power at `_block`

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### findBlockEpoch

```solidity
function findBlockEpoch(uint256 blk, uint256 maxEpoch) public view returns (uint256)
```

Binary search to estimate timestamp for block number
    @param blk Block to find
    @param maxEpoch Don't go beyond this epoch
    @return Approximate timestamp for block

### _checkPoint

```solidity
function _checkPoint(address addr, struct VotingEscrow.LockedBalance oldLocked, struct VotingEscrow.LockedBalance newLocked) internal
```

Record global and per-user data to checkpoint
    @param addr User's wallet address. No user checkpoint if 0x0
    @param oldLocked Previous locked amount / end lock time for the user
    @param newLocked New locked amount / end lock time for the user

### _depositFor

```solidity
function _depositFor(address addr, uint256 value, uint256 unlockTime, struct VotingEscrow.LockedBalance lockedBalance, enum VotingEscrow.OperationType t) internal
```

Deposit and lock tokens for a user
    @param addr User's wallet address
    @param value Amount to deposit
    @param unlockTime New time when to unlock the tokens, or 0 if unchanged
    @param lockedBalance Previous locked amount / timestamp
    @param t Operation type

### supplyAt

```solidity
function supplyAt(struct VotingEscrow.Point point, uint256 t) internal view returns (uint256)
```

Calculate total voting power at some point in the past
    @param point The point (bias/slope) to start search from
    @param t Time to calculate the total voting power at
    @return Total voting power at that time

### contractNotExpired

```solidity
modifier contractNotExpired()
```

