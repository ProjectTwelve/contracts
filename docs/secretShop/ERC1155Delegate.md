## ERC1155Delegate

### DELEGATION_CALLER

```solidity
bytes32 DELEGATION_CALLER
```

### PAUSABLE_CALLER

```solidity
bytes32 PAUSABLE_CALLER
```

### Pair

```solidity
struct Pair {
  uint256 salt;
  contract IERC1155 token;
  uint256 tokenId;
  uint256 amount;
}
```

### constructor

```solidity
constructor() public
```

### delegateType

```solidity
function delegateType() external pure returns (uint256)
```

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | delegateType the delegate's type |

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external pure returns (bytes4)
```

_Received function_

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) external pure returns (bytes4)
```

_Received function_

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### decode

```solidity
function decode(bytes data) public pure returns (struct ERC1155Delegate.Pair[])
```

_decode data to the array of Pair_

### executeSell

```solidity
function executeSell(address seller, address buyer, bytes data) public returns (bool)
```

_run the sell to transfer item_

| Name | Type | Description |
| ---- | ---- | ----------- |
| seller | address | address which sell the item |
| buyer | address | address which buy the item |
| data | bytes | the item's data, which will be decode as a array of Pair |

