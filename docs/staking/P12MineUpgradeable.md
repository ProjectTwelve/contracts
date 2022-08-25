## P12MineUpgradeable

### ONE

```solidity
uint256 ONE
```

### WEEK

```solidity
uint256 WEEK
```

### setP12CoinFactory

```solidity
function setP12CoinFactory(address newP12CoinFactory) external virtual
```

set new p12CoinFactory
  @param newP12CoinFactory address of p12CoinFactory

### setGaugeController

```solidity
function setGaugeController(contract IGaugeController newGaugeController) external virtual
```

set new gaugeController
  @param newGaugeController address of gaugeController

### poolLength

```solidity
function poolLength() external view virtual returns (uint256)
```

Get pool len

### withdrawEmergency

```solidity
function withdrawEmergency() external virtual
```

​    @notice withdraw token Emergency

### checkpoint

```solidity
function checkpoint(address lpToken) external
```

update checkpoint for pool
    @param lpToken Address of lpToken

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
function initialize(address p12Token_, address p12CoinFactory_, contract IGaugeController gaugeController_, uint256 delayK_, uint256 delayB_, uint256 rate_) public
```

Contract initialization
    @param p12Token_ Address of p12Token
    @param p12CoinFactory_ Address of p12CoinFactory
    @param gaugeController_ address of gaugeController
    @param delayK_ delayK_ is a coefficient
    @param delayB_ delayB_ is a coefficient

### getWithdrawUnlockTimestamp

```solidity
function getWithdrawUnlockTimestamp(address lpToken, uint256 amount) public view virtual returns (uint256)
```

get withdraw unlockTimestamp
    @param lpToken Address of lpToken
    @param amount Number of lpToken

### getPid

```solidity
function getPid(address lpToken) public view virtual returns (uint256)
```

Get pool id
    @param lpToken Address of lpToken

### getUserLpBalance

```solidity
function getUserLpBalance(address lpToken, address user) public view virtual returns (uint256)
```

Get user lpToken balance
    @param lpToken Address of lpToken
    @param user LpToken holder
    @return Get lpToken balance

### addLpTokenInfoForGameCreator

```solidity
function addLpTokenInfoForGameCreator(address lpToken, uint256 amount, address gameCoinCreator) public virtual
```

This method is only used when creating game coin in p12CoinFactory
    @param lpToken Address of lpToken
    @param gameCoinCreator user of game coin creator

### emergency

```solidity
function emergency() public virtual
```

set the isEmergency to true

### createPool

```solidity
function createPool(address lpToken) public virtual
```

Create a new pool
    @param lpToken Address of lpToken

### setDelayK

```solidity
function setDelayK(uint256 newDelayK) public virtual returns (bool)
```

Set delayK value 
    @param newDelayK Is a coefficient
    @return Get bool result

### setDelayB

```solidity
function setDelayB(uint256 newDelayB) public virtual returns (bool)
```

Set delayB value 
    @param newDelayB Is a coefficient
    @return Get bool result

### setRate

```solidity
function setRate(uint256 newRate) public virtual returns (bool)
```

set new rate
    @param newRate is p12 token inflation rate

### checkpointAll

```solidity
function checkpointAll() public virtual
```

update checkpoint for all pool

### deposit

```solidity
function deposit(address lpToken, uint256 amount) public virtual
```

Deposit lpToken
    @param lpToken Address of lpToken
    @param amount Number of lpToken

### queueWithdraw

```solidity
function queueWithdraw(address lpToken, uint256 amount) public virtual
```

Withdraw lpToken delay
  @param lpToken Address of lpToken
  @param amount Number of lpToken

### claim

```solidity
function claim(address lpToken) public virtual returns (uint256)
```

Get pending rewards
    @param lpToken Address of lpToken

### claimAll

```solidity
function claimAll() public virtual returns (uint256)
```

Get all pending rewards

### executeWithdraw

```solidity
function executeWithdraw(address lpToken, bytes32 id) public virtual
```

Withdraw lpToken
    @param lpToken Address of lpToken
    @param id Withdraw id

### withdrawAllLpTokenEmergency

```solidity
function withdrawAllLpTokenEmergency() public virtual
```

​    @notice withdraw lpToken Emergency

### withdrawLpTokenEmergency

```solidity
function withdrawLpTokenEmergency(address lpToken) public virtual
```

​    @notice withdraw all lpToken Emergency
    @param lpToken address of lpToken

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### _safeP12Transfer

```solidity
function _safeP12Transfer(address to, uint256 amount) internal virtual
```

Transfer p12 to user
    @param  to The address of receiver
    @param amount Number of p12

### _createWithdrawId

```solidity
function _createWithdrawId(address lpToken, uint256 amount, address to) internal virtual returns (bytes32 hash)
```

Create withdraw id
    @param lpToken Address of lpToken
    @param amount Number of lpToken
    @param to Address of receiver
    @return hash Get a withdraw Id

### _checkpoint

```solidity
function _checkpoint(uint256 pid) internal virtual
```

update checkpoint for pool
      @param pid Pool Id

### lpTokenExist

```solidity
modifier lpTokenExist(address lpToken)
```

### lpTokenNotExist

```solidity
modifier lpTokenNotExist(address lpToken)
```

### onlyP12FactoryOrOwner

```solidity
modifier onlyP12FactoryOrOwner()
```

### onlyP12Factory

```solidity
modifier onlyP12Factory()
```

### onlyEmergency

```solidity
modifier onlyEmergency()
```

