## SecretShopUpgradable

### RATE_BASE

```solidity
uint256 RATE_BASE
```

_precision of the parameters_

### receive

```solidity
receive() external payable
```

_for contract to receive native token_

### runSingle

```solidity
function runSingle(struct Market.Order order, struct Market.SettleShared shared, struct Market.SettleDetail detail) external virtual returns (uint256)
```

_run a single order_

| Name | Type | Description |
| ---- | ---- | ----------- |
| order | struct Market.Order | order by the maker |
| shared | struct Market.SettleShared | some option of the taker |
| detail | struct Market.SettleDetail | detail by the taker |

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
function initialize(uint256 feeCapPct_, address weth_) public
```

_initialize_

| Name | Type | Description |
| ---- | ---- | ----------- |
| feeCapPct_ | uint256 | max fee percentage |
| weth_ | address | address of wrapped eth |

### updateFeeCap

```solidity
function updateFeeCap(uint256 val) public virtual
```

| Name | Type | Description |
| ---- | ---- | ----------- |
| val | uint256 | new Fee Cap |

### updateDelegates

```solidity
function updateDelegates(address[] toAdd, address[] toRemove) public virtual
```

_update Delegates address_

| Name | Type | Description |
| ---- | ---- | ----------- |
| toAdd | address[] | the array of delegate address that want to add |
| toRemove | address[] | the array to delegate address that want to remove |

### updateCurrencies

```solidity
function updateCurrencies(contract IERC20Upgradeable[] toAdd, contract IERC20Upgradeable[] toRemove) public
```

_update Currencies address_

| Name | Type | Description |
| ---- | ---- | ----------- |
| toAdd | contract IERC20Upgradeable[] | the array of currency address that want to add |
| toRemove | contract IERC20Upgradeable[] | the array to currency address that want to remove |

### run

```solidity
function run(struct Market.RunInput input) public payable virtual
```

_Entry of a contract call_

| Name | Type | Description |
| ---- | ---- | ----------- |
| input | struct Market.RunInput | a struct that contains all data |

### _emitInventory

```solidity
function _emitInventory(bytes32 itemHash, struct Market.Order order, struct Market.OrderItem item, struct Market.SettleShared shared, struct Market.SettleDetail detail) internal virtual
```

### _run

```solidity
function _run(struct Market.Order order, struct Market.SettleShared shared, struct Market.SettleDetail detail) internal virtual returns (uint256)
```

_internal function, real implementation
make single trade to be achieved_

| Name | Type | Description |
| ---- | ---- | ----------- |
| order | struct Market.Order | order by the maker |
| shared | struct Market.SettleShared | some option of the taker |
| detail | struct Market.SettleDetail | detail by the taker |

### _takePayment

```solidity
function _takePayment(contract IERC20Upgradeable currency, address from, uint256 amount) internal virtual returns (uint256)
```

_transfer some kind ERC20 to this contract_

| Name | Type | Description |
| ---- | ---- | ----------- |
| currency | contract IERC20Upgradeable | currency's address |
| from | address | who pays |
| amount | uint256 | how much pay |

### _transferTo

```solidity
function _transferTo(contract IERC20Upgradeable currency, address to, uint256 amount) internal virtual
```

_transfer some kind ERC20_

| Name | Type | Description |
| ---- | ---- | ----------- |
| currency | contract IERC20Upgradeable | currency's address |
| to | address | who receive |
| amount | uint256 | how much receive |

### _distributeFeeAndProfit

```solidity
function _distributeFeeAndProfit(bytes32 itemHash, address seller, contract IERC20Upgradeable currency, struct Market.SettleDetail sd, uint256 price) internal virtual
```

_distribute fees and give extra to seller_

| Name | Type | Description |
| ---- | ---- | ----------- |
| itemHash | bytes32 | the item's hash |
| seller | address | who sell the item |
| currency | contract IERC20Upgradeable | currency's address |
| sd | struct Market.SettleDetail | detail by the taker |
| price | uint256 | the item's price |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

upgrade function

### _isNative

```solidity
function _isNative(contract IERC20Upgradeable currency) internal view virtual returns (bool)
```

_judge whether token is chain native token_

| Name | Type | Description |
| ---- | ---- | ----------- |
| currency | contract IERC20Upgradeable | address of the currency, 0 for native token |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool whether the token is a native token |

### _verifyOrderSignature

```solidity
function _verifyOrderSignature(struct Market.Order order) internal view virtual
```

_verify whether the order data is real, necessary for security_

| Name | Type | Description |
| ---- | ---- | ----------- |
| order | struct Market.Order | order by the maker |

### _hashItem

```solidity
function _hashItem(struct Market.Order order, struct Market.OrderItem item) internal view virtual returns (bytes32)
```

_hash an item Data to calculate itemHash_

| Name | Type | Description |
| ---- | ---- | ----------- |
| order | struct Market.Order | order by the maker |
| item | struct Market.OrderItem | which item to be hashed in the order |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | hash the item's hash, which is unique |

### _assertDelegation

```solidity
function _assertDelegation(struct Market.Order order, struct Market.SettleDetail detail) internal view virtual
```

_judge delegate type_

| Name | Type | Description |
| ---- | ---- | ----------- |
| order | struct Market.Order | order by the maker |
| detail | struct Market.SettleDetail | settle detail by the taker |

### _hash

```solidity
function _hash(struct Market.Order order) private pure returns (bytes32)
```

_hash typed data of an Order_

| Name | Type | Description |
| ---- | ---- | ----------- |
| order | struct Market.Order | order by the maker |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | hash typed data hash |

### _hash

```solidity
function _hash(struct Market.OrderItem[] orderItems) private pure returns (bytes32)
```

_hash typed data of a array of orderItem_

| Name | Type | Description |
| ---- | ---- | ----------- |
| orderItems | struct Market.OrderItem[] |  |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | hash typed data hash |

### _hash

```solidity
function _hash(struct Market.OrderItem orderItem) private pure returns (bytes32)
```

_hash typed data of an orderItem_

| Name | Type | Description |
| ---- | ---- | ----------- |
| orderItem | struct Market.OrderItem | orderItem |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | hash typed data hash |

