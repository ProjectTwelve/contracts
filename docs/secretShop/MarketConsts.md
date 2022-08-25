## Market

### INTENT_SELL

```solidity
uint256 INTENT_SELL
```

### INTENT_BUY

```solidity
uint256 INTENT_BUY
```

### SIGN_V1

```solidity
uint8 SIGN_V1
```

### OrderItem

```solidity
struct OrderItem {
  uint256 price;
  bytes data;
}

```

### Order

```solidity
struct Order {
  uint256 salt;
  address user;
  uint256 network;
  uint256 intent;
  uint256 delegateType;
  uint256 deadline;
  contract IERC20Upgradeable currency;
  struct Market.OrderItem[] items;
  bytes32 r;
  bytes32 s;
  uint8 v;
  uint8 signVersion;
}
```

### Fee

```solidity
struct Fee {
  uint256 percentage;
  address to;
}

```

### SettleDetail

```solidity
struct SettleDetail {
  enum Market.Op op;
  uint256 orderIdx;
  uint256 itemIdx;
  uint256 price;
  bytes32 itemHash;
  contract IDelegate executionDelegate;
  struct Market.Fee[] fees;
}
```

### SettleShared

```solidity
struct SettleShared {
  uint256 salt;
  uint256 deadline;
  address user;
  bool canFail;
}

```

### RunInput

```solidity
struct RunInput {
  struct Market.Order[] orders;
  struct Market.SettleDetail[] details;
  struct Market.SettleShared shared;
}
```

### InvStatus

```solidity
enum InvStatus {
  NEW,
  COMPLETE,
  CANCELLED
}

```

### Op

```solidity
enum Op {
  INVALID,
  COMPLETE_SELL_OFFER,
  COMPLETE_BUY_OFFER,
  CANCEL_OFFER
}

```

### DelegationType

```solidity
enum DelegationType {
  INVALID,
  ERC1155,
  ERC721
}

```
