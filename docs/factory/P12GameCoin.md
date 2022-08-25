## P12GameCoin

### gameId

```solidity
string gameId
```

_Off-chain data, game id_

### gameCoinIconUrl

```solidity
string gameCoinIconUrl
```

_game coin's logo_

### constructor

```solidity
constructor(string name_, string symbol_, string gameId_, string gameCoinIconUrl_, uint256 amount_) public
```

| Name              | Type    | Description             |
| ----------------- | ------- | ----------------------- |
| name\_            | string  | game coin name          |
| symbol\_          | string  | game coin symbol        |
| gameId\_          | string  | gameId                  |
| gameCoinIconUrl\_ | string  | game coin icon's url    |
| amount\_          | uint256 | amount of first minting |

### mint

```solidity
function mint(address to, uint256 amount) public
```

_mint function, the Owner will only be factory contract_

| Name   | Type    | Description                             |
| ------ | ------- | --------------------------------------- |
| to     | address | address which receive newly-minted coin |
| amount | uint256 | amount of the minting                   |

### transferWithAccount

```solidity
function transferWithAccount(address recipient, string account, uint256 amount) external
```

_transfer function for just a basic transfer with an off-chain account
called when a user want to deposit his coin from on-chain to off-chain_

| Name      | Type    | Description                                                  |
| --------- | ------- | ------------------------------------------------------------ |
| recipient | address | address which receive the coin, usually be custodian address |
| account   | string  | off-chain account                                            |
| amount    | uint256 | amount of this transfer                                      |
