## ControllerStorage

### votingEscrow

```solidity
contract IVotingEscrow votingEscrow
```

### p12CoinFactory

```solidity
address p12CoinFactory
```

### nGaugeTypes

```solidity
int128 nGaugeTypes
```

### nGauges

```solidity
int128 nGauges
```

### timeTotal

```solidity
uint256 timeTotal
```

### \_\_gap

```solidity
uint256[45] __gap
```

### gaugeTypeNames

```solidity
mapping(int128 => string) gaugeTypeNames
```

### gauges

```solidity
mapping(int128 => address) gauges
```

### gaugeTypes

```solidity
mapping(address => int128) gaugeTypes
```

### voteUserSlopes

```solidity
mapping(address => mapping(address => struct ControllerStorage.VotedSlope)) voteUserSlopes
```

### voteUserPower

```solidity
mapping(address => uint256) voteUserPower
```

### lastUserVote

```solidity
mapping(address => mapping(address => uint256)) lastUserVote
```

### pointsWeight

```solidity
mapping(address => mapping(uint256 => struct ControllerStorage.Point)) pointsWeight
```

### changesWeight

```solidity
mapping(address => mapping(uint256 => uint256)) changesWeight
```

### timeWeight

```solidity
mapping(address => uint256) timeWeight
```

### pointsSum

```solidity
mapping(int128 => mapping(uint256 => struct ControllerStorage.Point)) pointsSum
```

### changesSum

```solidity
mapping(int128 => mapping(uint256 => uint256)) changesSum
```

### timeSum

```solidity
mapping(int128 => uint256) timeSum
```

### pointsTotal

```solidity
mapping(uint256 => uint256) pointsTotal
```

### pointsTypeWeight

```solidity
mapping(int128 => mapping(uint256 => uint256)) pointsTypeWeight
```

### timeTypeWeight

```solidity
mapping(int128 => uint256) timeTypeWeight
```

### Point

```solidity
struct Point {
  uint256 bias;
  uint256 slope;
}

```

### VotedSlope

```solidity
struct VotedSlope {
  uint256 slope;
  uint256 power;
  uint256 end;
}

```

### TmpBiasAndSlope

```solidity
struct TmpBiasAndSlope {
  uint256 oldWeightBias;
  uint256 oldWeightSlope;
  uint256 oldSumBias;
  uint256 oldSumSlope;
}

```

### TmpBias

```solidity
struct TmpBias {
  uint256 oldBias;
  uint256 newBias;
}

```
