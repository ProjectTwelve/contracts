## IP12AssetFactoryUpgradable

### CollectionCreated

```solidity
event CollectionCreated(address collection, address developer)
```

_record a new Collection Created_

### SftCreated

```solidity
event SftCreated(address collection, uint256 tokenId, uint256 amount)
```

_record a new Sft created, sft is semi-fungible token, as it's in a ERC1155 contract_

### SetP12Factory

```solidity
event SetP12Factory(address oldP12Factory, address newP12Factory)
```

### setP12CoinFactory

```solidity
function setP12CoinFactory(address newP12Factory) external
```

### createCollection

```solidity
function createCollection(string gameId, string) external
```

### createAssetAndMint

```solidity
function createAssetAndMint(address, uint256, string) external
```

### updateCollectionUri

```solidity
function updateCollectionUri(address, string) external
```

### updateSftUri

```solidity
function updateSftUri(address, uint256, string) external
```

