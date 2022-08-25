## IP12MineUpgradeable

### Deposit

```solidity
event Deposit(address user, uint256 pid, uint256 amount, uint256 userAmount, uint256 poolAmount)
```

### ExecuteWithdraw

```solidity
event ExecuteWithdraw(address user, uint256 pid, bytes32 withdrawId, uint256 amount, uint256 userAmount, uint256 poolAmount)
```

### QueueWithdraw

```solidity
event QueueWithdraw(address user, uint256 pid, uint256 amount, bytes32 newWithdrawId, uint256 unlockTimestamp)
```

### Claim

```solidity
event Claim(address user, uint256 amount)
```

### SetDelayB

```solidity
event SetDelayB(uint256 oldDelayB, uint256 newDelayB)
```

### SetDelayK

```solidity
event SetDelayK(uint256 oldDelayK, uint256 newDelayK)
```

### SetRate

```solidity
event SetRate(uint256 oldRate, uint256 newRate)
```

### SetP12Factory

```solidity
event SetP12Factory(address oldP12Factory, address newP12Factory)
```

### SetGaugeController

```solidity
event SetGaugeController(contract IGaugeController oldGaugeController, contract IGaugeController newGaugeController)
```

### WithdrawLpTokenEmergency

```solidity
event WithdrawLpTokenEmergency(address lpToken, uint256 amount)
```

### Emergency

```solidity
event Emergency(address executor, uint256 emergencyUnlockTime)
```

### Checkpoint

```solidity
event Checkpoint(address lpToken, uint256 poolAmount, uint256 accP12PerShare)
```

### poolLength

```solidity
function poolLength() external returns (uint256)
```

### getPid

```solidity
function getPid(address lpToken) external returns (uint256)
```

### getUserLpBalance

```solidity
function getUserLpBalance(address lpToken, address user) external returns (uint256)
```

### checkpointAll

```solidity
function checkpointAll() external
```

### getWithdrawUnlockTimestamp

```solidity
function getWithdrawUnlockTimestamp(address lpToken, uint256 amount) external returns (uint256)
```

### withdrawEmergency

```solidity
function withdrawEmergency() external
```

### withdrawLpTokenEmergency

```solidity
function withdrawLpTokenEmergency(address lpToken) external
```

### withdrawAllLpTokenEmergency

```solidity
function withdrawAllLpTokenEmergency() external
```

### emergency

```solidity
function emergency() external
```

### createPool

```solidity
function createPool(address lpToken) external
```

### setDelayK

```solidity
function setDelayK(uint256 delayK) external returns (bool)
```

### setDelayB

```solidity
function setDelayB(uint256 delayB) external returns (bool)
```

### deposit

```solidity
function deposit(address lpToken, uint256 amount) external
```

### setRate

```solidity
function setRate(uint256 newRate) external returns (bool)
```

### setP12CoinFactory

```solidity
function setP12CoinFactory(address newP12Factory) external
```

### setGaugeController

```solidity
function setGaugeController(contract IGaugeController newGaugeController) external
```

### executeWithdraw

```solidity
function executeWithdraw(address lpToken, bytes32 id) external
```

### queueWithdraw

```solidity
function queueWithdraw(address lpToken, uint256 amount) external
```

### addLpTokenInfoForGameCreator

```solidity
function addLpTokenInfoForGameCreator(address lpToken, uint256 amount, address gameCoinCreator) external
```

### claim

```solidity
function claim(address lpToken) external returns (uint256)
```

### claimAll

```solidity
function claimAll() external returns (uint256)
```

### checkpoint

```solidity
function checkpoint(address lpToken) external
```

