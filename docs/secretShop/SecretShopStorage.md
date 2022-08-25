## SecretShopStorage

### feeCapPct

```solidity
uint256 feeCapPct
```

_fee Cap_

### domainSeparator

```solidity
bytes32 domainSeparator
```

_DOMAIN_SEPARATOR for EIP712_

### weth

```solidity
contract IWETHUpgradable weth
```

### \_\_gap

```solidity
uint256[47] __gap
```

### delegates

```solidity
mapping(address => bool) delegates
```

_store delegator contract status_

### currencies

```solidity
mapping(contract IERC20Upgradeable => bool) currencies
```

_store currency supported_

### inventoryStatus

```solidity
mapping(bytes32 => enum Market.InvStatus) inventoryStatus
```

_store itemHash status_
