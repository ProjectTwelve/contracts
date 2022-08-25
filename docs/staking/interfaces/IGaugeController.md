## IGaugeController

### CommitOwnership

```solidity
event CommitOwnership(address admin)
```

### ApplyOwnership

```solidity
event ApplyOwnership(address admin)
```

### AddType

```solidity
event AddType(string name, int128 typeId)
```

### NewTypeWeight

```solidity
event NewTypeWeight(int128 typeId, uint256 time, uint256 weight, uint256 totalWeight)
```

### NewGaugeWeight

```solidity
event NewGaugeWeight(address gaugeAddress, uint256 time, uint256 weight, uint256 totalWeight)
```

### VoteForGauge

```solidity
event VoteForGauge(uint256 time, address user, address gaugeAddress, uint256 weight)
```

### NewGauge

```solidity
event NewGauge(address addr, int128 gaugeType, uint256 weight)
```

### SetVotingEscrow

```solidity
event SetVotingEscrow(contract IVotingEscrow oldVotingEscrow, contract IVotingEscrow newVotingEscrow)
```

### SetP12Factory

```solidity
event SetP12Factory(address oldP12Factory, address newP12Factory)
```

### getGaugeTypes

```solidity
function getGaugeTypes(address addr) external returns (int128)
```

### checkpoint

```solidity
function checkpoint() external
```

### gaugeRelativeWeightWrite

```solidity
function gaugeRelativeWeightWrite(address addr, uint256 time) external returns (uint256)
```

### changeTypeWeight

```solidity
function changeTypeWeight(int128 typeId, uint256 weight) external
```

### changeGaugeWeight

```solidity
function changeGaugeWeight(address addr, uint256 weight) external
```

### voteForGaugeWeights

```solidity
function voteForGaugeWeights(address gaugeAddr, uint256 userWeight) external
```

### checkpointGauge

```solidity
function checkpointGauge(address addr) external
```

### gaugeRelativeWeight

```solidity
function gaugeRelativeWeight(address lpToken, uint256 time) external returns (uint256)
```

### getGaugeWeight

```solidity
function getGaugeWeight(address addr) external returns (uint256)
```

### getTypeWeight

```solidity
function getTypeWeight(int128 typeId) external returns (uint256)
```

### getTotalWeight

```solidity
function getTotalWeight() external returns (uint256)
```

### getWeightsSumPerType

```solidity
function getWeightsSumPerType(int128 typeId) external returns (uint256)
```

### addGauge

```solidity
function addGauge(address addr, int128 gaugeType, uint256 weight) external
```

### addType

```solidity
function addType(string name, uint256 weight) external
```

### setVotingEscrow

```solidity
function setVotingEscrow(contract IVotingEscrow newVotingEscrow) external
```

### setP12CoinFactory

```solidity
function setP12CoinFactory(address newP12Factory) external
```

