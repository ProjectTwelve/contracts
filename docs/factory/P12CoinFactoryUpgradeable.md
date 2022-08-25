## P12CoinFactoryUpgradeable

### setDev

```solidity
function setDev(address newDev) external virtual
```

_set dev address_

| Name | Type | Description |
| ---- | ---- | ----------- |
| newDev | address | new dev address |

### setP12Mine

```solidity
function setP12Mine(contract IP12MineUpgradeable newP12Mine) external virtual
```

_set p12mine contract address_

| Name | Type | Description |
| ---- | ---- | ----------- |
| newP12Mine | contract IP12MineUpgradeable | new p12mine address |

### setGaugeController

```solidity
function setGaugeController(contract IGaugeController newGaugeController) external virtual
```

_set gaugeController contract address_

| Name | Type | Description |
| ---- | ---- | ----------- |
| newGaugeController | contract IGaugeController | new gaugeController address |

### setP12Token

```solidity
function setP12Token(address newP12Token) external virtual
```

_set p12Token address
reserved only during development_

| Name | Type | Description |
| ---- | ---- | ----------- |
| newP12Token | address | new p12Token address |

### setUniswapFactory

```solidity
function setUniswapFactory(contract IUniswapV2Factory newUniswapFactory) external virtual
```

_set uniswapFactory address
reserved only during development_

| Name | Type | Description |
| ---- | ---- | ----------- |
| newUniswapFactory | contract IUniswapV2Factory | new UniswapFactory address |

### setUniswapRouter

```solidity
function setUniswapRouter(contract IUniswapV2Router02 newUniswapRouter) external virtual
```

_set uniswapRouter address
reserved only during development_

| Name | Type | Description |
| ---- | ---- | ----------- |
| newUniswapRouter | contract IUniswapV2Router02 | new uniswapRouter address |

### register

```solidity
function register(string gameId, address developer) external virtual
```

_create binding between game and developer, only called by p12 backend_

| Name | Type | Description |
| ---- | ---- | ----------- |
| gameId | string | game id |
| developer | address | developer address, who own this game |

### create

```solidity
function create(string name, string symbol, string gameId, string gameCoinIconUrl, uint256 amountGameCoin, uint256 amountP12) external virtual returns (contract IP12GameCoin gameCoinAddress)
```

_developer first create their game coin_

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | new game coin's name |
| symbol | string | game coin's symbol |
| gameId | string | the game's id |
| gameCoinIconUrl | string | game coin icon's url |
| amountGameCoin | uint256 | how many coin first mint |
| amountP12 | uint256 | how many P12 coin developer would stake |

| Name | Type | Description |
| ---- | ---- | ----------- |
| gameCoinAddress | contract IP12GameCoin | the address of the new game coin |

### queueMintCoin

```solidity
function queueMintCoin(string gameId, contract IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external virtual returns (bool success)
```

_if developer want to mint after create coin, developer must declare first_

| Name | Type | Description |
| ---- | ---- | ----------- |
| gameId | string | game's id |
| gameCoinAddress | contract IP12GameCoin | game coin's address |
| amountGameCoin | uint256 | how many developer want to mint |

### executeMintCoin

```solidity
function executeMintCoin(contract IP12GameCoin gameCoinAddress, bytes32 mintId) external virtual returns (bool)
```

_when time is up, anyone can call this function to make the mint executed_

| Name | Type | Description |
| ---- | ---- | ----------- |
| gameCoinAddress | contract IP12GameCoin | address of the game coin |
| mintId | bytes32 | a unique id to identify a mint, developer can get it after declare |

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool whether the operation success |

### withdraw

```solidity
function withdraw(address userAddress, contract IP12GameCoin gameCoinAddress, uint256 amountGameCoin) external virtual returns (bool)
```

called when user want to withdraw his game coin from custodian address

| Name | Type | Description |
| ---- | ---- | ----------- |
| userAddress | address | user's address |
| gameCoinAddress | contract IP12GameCoin | gameCoin's address |
| amountGameCoin | uint256 | how many user want to withdraw |

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
function initialize(address p12_, contract IUniswapV2Factory uniswapFactory_, contract IUniswapV2Router02 uniswapRouter_, uint256 effectiveTime_, bytes32 initHash_) public
```

### setDelayK

```solidity
function setDelayK(uint256 newDelayK) public virtual returns (bool)
```

_set linear function's K parameter_

| Name | Type | Description |
| ---- | ---- | ----------- |
| newDelayK | uint256 | new K parameter |

### setDelayB

```solidity
function setDelayB(uint256 newDelayB) public virtual returns (bool)
```

_set linear function's B parameter_

| Name | Type | Description |
| ---- | ---- | ----------- |
| newDelayB | uint256 | new B parameter |

### getMintFee

```solidity
function getMintFee(contract IP12GameCoin gameCoinAddress, uint256 amountGameCoin) public view virtual returns (uint256 amountP12)
```

_calculate the MintFee in P12_

### getMintDelay

```solidity
function getMintDelay(contract IP12GameCoin gameCoinAddress, uint256 amountGameCoin) public view virtual returns (uint256 time)
```

_linear function to calculate the delay time
delayB is the minimum delay period, even someone mint zero token,
there still be delayB period before someone can really mint zero token
delayK is the parameter to take the ratio of new amount in to account
For example, the initial supply of Game Coin is 100k. If developer want
to mint 100k, developer needs to real mint it after `delayK + delayB`. If
developer want to mint 200k, developer has to real mint it after `2DelayK +
delayB`.
          ^
        t +            /
          |          /
          |        /
      2k+b|      /
          |    /
       k+b|  / 
          |/ 
         b|
          0----p---2p---------> amount_

### _create

```solidity
function _create(string name, string symbol, string gameId, string gameCoinIconUrl, uint256 amountGameCoin) internal virtual returns (contract P12GameCoin gameCoinAddress)
```

_function to create a game coin contract_

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | game coin name |
| symbol | string | game coin symbol |
| gameId | string | game id |
| gameCoinIconUrl | string | game coin icon's url |
| amountGameCoin | uint256 | how many for first mint |

### _hashOperation

```solidity
function _hashOperation(contract IP12GameCoin gameCoinAddress, address declarer, uint256 amount, uint256 timestamp, bytes32 salt) internal virtual returns (bytes32 hash)
```

_hash function to general mintId_

| Name | Type | Description |
| ---- | ---- | ----------- |
| gameCoinAddress | contract IP12GameCoin | game coin address |
| declarer | address | address which declare to mint game coin |
| amount | uint256 | how much to mint |
| timestamp | uint256 | time when declare |
| salt | bytes32 | a random bytes32 |

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | mintId |

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

### getBlockTimestamp

```solidity
function getBlockTimestamp() internal view virtual returns (uint256)
```

_get current block's timestamp_

### compareStrings

```solidity
function compareStrings(string a, string b) internal pure virtual returns (bool)
```

_compare two string and judge whether they are the same_

### onlyDev

```solidity
modifier onlyDev()
```

