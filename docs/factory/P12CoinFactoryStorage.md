## P12CoinFactoryStorage

### p12

```solidity
address p12
```

_p12 ERC20 address_

### uniswapRouter

```solidity
contract IUniswapV2Router02 uniswapRouter
```

_uniswap v2 Router address_

### uniswapFactory

```solidity
contract IUniswapV2Factory uniswapFactory
```

_uniswap v2 Factory address_

### delayK

```solidity
uint256 delayK
```

_length of cast delay time is a linear function of percentage of additional issues,
delayK and delayB is the linear function's parameter which could be changed later_

### delayB

```solidity
uint256 delayB
```

### _initHash

```solidity
bytes32 _initHash
```

_a random hash value for calculate mintId_

### addLiquidityEffectiveTime

```solidity
uint256 addLiquidityEffectiveTime
```

### p12Mine

```solidity
contract IP12MineUpgradeable p12Mine
```

_p12 staking contract_

### dev

```solidity
address dev
```

### gaugeController

```solidity
contract IGaugeController gaugeController
```

### __gap

```solidity
uint256[40] __gap
```

### allGames

```solidity
mapping(string => address) allGames
```

### allGameCoins

```solidity
mapping(contract IP12GameCoin => string) allGameCoins
```

### coinMintRecords

```solidity
mapping(contract IP12GameCoin => mapping(bytes32 => struct P12CoinFactoryStorage.MintCoinInfo)) coinMintRecords
```

### preMintIds

```solidity
mapping(contract IP12GameCoin => bytes32) preMintIds
```

### MintCoinInfo

```solidity
struct MintCoinInfo {
  uint256 amount;
  uint256 unlockTimestamp;
  bool executed;
}
```

