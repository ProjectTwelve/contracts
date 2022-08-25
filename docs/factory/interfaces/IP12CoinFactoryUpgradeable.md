## IP12CoinFactoryUpgradeable

### register

```solidity
function register(string gameId, address developer) external
```

### create

```solidity
function create(string name, string symbol, string gameId, string gameCoinIconUrl, uint256 amountGameCoin, uint256 amountP12) external returns (contract IP12GameCoin)
```

### queueMintCoin

```solidity
function queueMintCoin(string gameId, contract IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external returns (bool)
```

### executeMintCoin

```solidity
function executeMintCoin(contract IP12GameCoin gameCoinAddress, bytes32 mintId) external returns (bool)
```

### withdraw

```solidity
function withdraw(address userAddress, contract IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external returns (bool)
```

### setDev

```solidity
function setDev(address newDev) external
```

### setP12Mine

```solidity
function setP12Mine(contract IP12MineUpgradeable newP12Mine) external
```

### setGaugeController

```solidity
function setGaugeController(contract IGaugeController newGaugeController) external
```

### setUniswapFactory

```solidity
function setUniswapFactory(contract IUniswapV2Factory newUniswapFactory) external
```

### setUniswapRouter

```solidity
function setUniswapRouter(contract IUniswapV2Router02 newUniswapRouter) external
```

### setP12Token

```solidity
function setP12Token(address newP12Token) external
```

### getMintFee

```solidity
function getMintFee(contract IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external view returns (uint256)
```

### getMintDelay

```solidity
function getMintDelay(contract IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external view returns (uint256)
```

### setDelayK

```solidity
function setDelayK(uint256 delayK) external returns (bool)
```

### setDelayB

```solidity
function setDelayB(uint256 delayB) external returns (bool)
```

### RegisterGame

```solidity
event RegisterGame(string gameId, address developer)
```

### CreateGameCoin

```solidity
event CreateGameCoin(contract IP12GameCoin gameCoinAddress, string gameId, uint256 amountP12)
```

### QueueMintCoin

```solidity
event QueueMintCoin(bytes32 mintId, contract IP12GameCoin gameCoinAddress, uint256 mintAmount, uint256 unlockTimestamp, uint256 amountP12)
```

### ExecuteMintCoin

```solidity
event ExecuteMintCoin(bytes32 mintId, contract IP12GameCoin gameCoinAddress, address executor)
```

### Withdraw

```solidity
event Withdraw(address userAddress, contract IP12GameCoin gameCoinAddress, uint256 amountGameCoin)
```

### SetDev

```solidity
event SetDev(address oldDev, address newDev)
```

### SetP12Mine

```solidity
event SetP12Mine(contract IP12MineUpgradeable oldP12Mine, contract IP12MineUpgradeable newP12Mine)
```

### SetGaugeController

```solidity
event SetGaugeController(contract IGaugeController oldGaugeController, contract IGaugeController newGaugeController)
```

### SetUniswapFactory

```solidity
event SetUniswapFactory(contract IUniswapV2Factory oldUniswapFactory, contract IUniswapV2Factory newUniswapFactory)
```

### SetUniswapRouter

```solidity
event SetUniswapRouter(contract IUniswapV2Router02 oldUniswapRouter, contract IUniswapV2Router02 newUniswapRouter)
```

### SetP12Token

```solidity
event SetP12Token(address oldP12Token, address newP12Token)
```

### SetDelayB

```solidity
event SetDelayB(uint256 oldDelayB, uint256 newDelayB)
```

### SetDelayK

```solidity
event SetDelayK(uint256 oldDelayK, uint256 newDelayK)
```
