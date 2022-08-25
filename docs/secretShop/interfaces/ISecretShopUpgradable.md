## ISecretShopUpgradable

### EvProfit

```solidity
event EvProfit(bytes32 itemHash, address currency, address to, uint256 amount)
```

_event to record how much seller earns_

### EvInventory

```solidity
event EvInventory(bytes32 itemHash, address maker, address taker, uint256 orderSalt, uint256 settleSalt, uint256 intent, uint256 delegateType, uint256 deadline, contract IERC20Upgradeable currency, struct Market.OrderItem item, struct Market.SettleDetail detail)
```

_event to record a item order matched_

### EvDelegate

```solidity
event EvDelegate(address delegate, bool isRemoval)
```

_event to record delegator contract change_

### EvCurrency

```solidity
event EvCurrency(contract IERC20Upgradeable currency, bool isRemoval)
```

_event to record currency supported change_

### EvFeeCapUpdate

```solidity
event EvFeeCapUpdate(uint256 newValue)
```

_event to record fee update_

### EvCancel

```solidity
event EvCancel(bytes32 itemHash)
```

_event to record a order canceled_

### EvFailure

```solidity
event EvFailure(uint256 index, bytes error)
```

_event to record a order failing_

### runSingle

```solidity
function runSingle(struct Market.Order, struct Market.SettleShared, struct Market.SettleDetail) external returns (uint256)
```

### updateFeeCap

```solidity
function updateFeeCap(uint256) external
```

### updateDelegates

```solidity
function updateDelegates(address[], address[]) external
```

### updateCurrencies

```solidity
function updateCurrencies(contract IERC20Upgradeable[], contract IERC20Upgradeable[]) external
```

### run

```solidity
function run(struct Market.RunInput input) external payable
```
