## GaugeControllerUpgradeable

### WEEK

```solidity
uint256 WEEK
```

### MULTIPLIER

```solidity
uint256 MULTIPLIER
```

### WEIGHT_VOTE_DELAY

```solidity
uint256 WEIGHT_VOTE_DELAY
```

### setVotingEscrow

```solidity
function setVotingEscrow(contract IVotingEscrow newVotingEscrow) external virtual
```

set new votingEscrow
@param newVotingEscrow address of votingEscrow

### setP12CoinFactory

```solidity
function setP12CoinFactory(address newP12Factory) external virtual
```

set new p12CoinFactory
@param newP12Factory address of newP12Factory

### getGaugeTypes

```solidity
function getGaugeTypes(address addr) external view virtual returns (int128)
```

Get gauge type for address
@param addr Gauge address
@return Gauge type id

### addGauge

```solidity
function addGauge(address addr, int128 gaugeType, uint256 weight) external virtual
```

Add gauge `addr` of type `gaugeType` with weight `weight`
@param addr Gauge address
@param gaugeType Gauge type
@param weight Gauge weight

### checkpoint

```solidity
function checkpoint() external virtual
```

Checkpoint to fill data common for all gauges

### checkpointGauge

```solidity
function checkpointGauge(address addr) external virtual
```

Checkpoint to fill data for both a specific gauge and common for all gauges
@param addr Gauge address

### gaugeRelativeWeight

```solidity
function gaugeRelativeWeight(address addr, uint256 time) external view virtual returns (uint256)
```

Get Gauge relative weight (not more than 1.0) normalized to 1e18
(e.g. 1.0 == 1e18). Inflation which will be received by it is
inflation_rate \* relative_weight / 1e18
@param addr Gauge address
@param time Relative weight at the specified timestamp in the past or present
@return Value of relative weight normalized to 1e18

### gaugeRelativeWeightWrite

```solidity
function gaugeRelativeWeightWrite(address addr, uint256 time) external virtual returns (uint256)
```

Get gauge weight normalized to 1e18 and also fill all the unfilled
values for type and gauge records
@dev Any address can call, however nothing is recorded if the values are filled already
@param addr Gauge address
@param time Relative weight at the specified timestamp in the past or present
@return Value of relative weight normalized to 1e18

### addType

```solidity
function addType(string name, uint256 weight) external virtual
```

Add gauge type with name `name` and weight `weight`
@param name Name of gauge type
@param weight Weight of gauge type

### changeTypeWeight

```solidity
function changeTypeWeight(int128 typeId, uint256 weight) external virtual
```

Change gauge type `typeId` weight to `weight`
@param typeId Gauge type id
@param weight New Gauge weight

### changeGaugeWeight

```solidity
function changeGaugeWeight(address addr, uint256 weight) external virtual
```

Change weight of gauge `addr` to `weight`
@param addr `GaugeController` contract address
@param weight New Gauge weight

### voteForGaugeWeights

```solidity
function voteForGaugeWeights(address gaugeAddr, uint256 userWeight) external virtual
```

Allocate voting power for changing pool weights
@param gaugeAddr Gauge which `msg.sender` votes for
@param userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0

### getGaugeWeight

```solidity
function getGaugeWeight(address addr) external view virtual returns (uint256)
```

Get current gauge weight
@param addr Gauge address
@return Gauge weight

### getTypeWeight

```solidity
function getTypeWeight(int128 typeId) external view virtual returns (uint256)
```

Get current type weight
@param typeId Type id
@return Type weight

### getTotalWeight

```solidity
function getTotalWeight() external view virtual returns (uint256)
```

Get current total (type-weighted) weight
@return Total weight

### getWeightsSumPerType

```solidity
function getWeightsSumPerType(int128 typeId) external view virtual returns (uint256)
```

Get sum of gauge weights per type
@param typeId Type id
@return Sum of gauge weights

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### initialize

```solidity
function initialize(address votingEscrow_, address p12CoinFactory_) public
```

### \_authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

\_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

````solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### _getTypeWeight

```solidity
function _getTypeWeight(int128 gaugeType) internal virtual returns (uint256)
````

Fill historic type weights week-over-week for missed checkins
and return the type weight for the future week
@param gaugeType Gauge type id
@return Type weight

### \_getSum

```solidity
function _getSum(int128 gaugeType) internal virtual returns (uint256)
```

Fill sum of gauge weights for the same type week-over-week for
missed checkins and return the sum for the future week
@param gaugeType Gauge type id
@return Sum of weights

### \_getTotal

```solidity
function _getTotal() internal virtual returns (uint256)
```

Fill historic total weights week-over-week for missed checkins
and return the total for the future week
@return Total weight

### \_getWeight

```solidity
function _getWeight(address gaugeAddr) internal virtual returns (uint256)
```

Fill historic gauge weights week-over-week for missed checkins
and return the total for the future week
@param gaugeAddr Address of the gauge
@return Gauge weight

### \_gaugeRelativeWeight

```solidity
function _gaugeRelativeWeight(address addr, uint256 time) internal view virtual returns (uint256)
```

Get Gauge relative weight (not more than 1.0) normalized to 1e18
(e.g. 1.0 == 1e18). Inflation which will be received by it is
inflation_rate \* relative_weight / 1e18
@param addr Gauge address
@param time Relative weight at the specified timestamp in the past or present
@return Value of relative weight normalized to 1e18

### \_changeTypeWeight

```solidity
function _changeTypeWeight(int128 typeId, uint256 weight) internal virtual
```

### \_changeGaugeWeight

```solidity
function _changeGaugeWeight(address addr, uint256 weight) internal virtual
```
