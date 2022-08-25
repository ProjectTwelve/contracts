## P12MineStorage

### p12CoinFactory

```solidity
address p12CoinFactory
```

### p12Token

```solidity
address p12Token
```

### gaugeController

```solidity
contract IGaugeController gaugeController
```

### p12RewardVault

```solidity
contract IP12RewardVault p12RewardVault
```

### delayK

```solidity
uint256 delayK
```

### delayB

```solidity
uint256 delayB
```

### rate

```solidity
uint256 rate
```

### poolInfos

```solidity
struct P12MineStorage.PoolInfo[] poolInfos
```

### isEmergency

```solidity
bool isEmergency
```

### emergencyUnlockTime

```solidity
uint256 emergencyUnlockTime
```

### \_\_gap

```solidity
uint256[40] __gap
```

### lpTokenRegistry

```solidity
mapping(address => uint256) lpTokenRegistry
```

### userInfo

```solidity
mapping(uint256 => mapping(address => struct P12MineStorage.UserInfo)) userInfo
```

### realizedReward

```solidity
mapping(address => uint256) realizedReward
```

### periodTimestamp

```solidity
mapping(address => mapping(uint256 => uint256)) periodTimestamp
```

### preWithdrawIds

```solidity
mapping(address => bytes32) preWithdrawIds
```

### withdrawInfos

```solidity
mapping(address => mapping(bytes32 => struct P12MineStorage.WithdrawInfo)) withdrawInfos
```

### UserInfo

```solidity
struct UserInfo {
  uint256 amount;
  uint256 rewardDebt;
}

```

### PoolInfo

```solidity
struct PoolInfo {
  address lpToken;
  uint256 accP12PerShare;
  uint256 amount;
  uint256 period;
}

```

### WithdrawInfo

```solidity
struct WithdrawInfo {
  address who;
  uint256 amount;
  uint256 unlockTimestamp;
  bool executed;
}

```
