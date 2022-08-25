## P12AssetFactoryUpgradable

### setP12CoinFactory

```solidity
function setP12CoinFactory(address newP12CoinFactory) external virtual
```

set new p12CoinFactory
  @param newP12CoinFactory address of p12CoinFactory

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
function initialize(address p12CoinFactory_) public
```

### createCollection

```solidity
function createCollection(string gameId, string contractURI) public
```

_create Collection_

| Name | Type | Description |
| ---- | ---- | ----------- |
| gameId | string | a off-chain game id |
| contractURI | string | contract-level metadata uri |

### createAssetAndMint

```solidity
function createAssetAndMint(address collection, uint256 amount, string uri) public
```

_create asset and mint to msg.sender address_

| Name | Type | Description |
| ---- | ---- | ----------- |
| collection | address | which collection want to create |
| amount | uint256 | amount of asset |
| uri | string | new asset's metadata uri |

### updateCollectionUri

```solidity
function updateCollectionUri(address collection, string newUri) public
```

_update Collection Uri_

| Name | Type | Description |
| ---- | ---- | ----------- |
| collection | address | collection address |
| newUri | string | new Contract-level metadata uri |

### updateSftUri

```solidity
function updateSftUri(address collection, uint256 tokenId, string newUri) public
```

_update Sft Uri_

| Name | Type | Description |
| ---- | ---- | ----------- |
| collection | address | collection address |
| tokenId | uint256 | token id |
| newUri | string | new metadata uri |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

upgrade function

### onlyDeveloper

```solidity
modifier onlyDeveloper(string gameId)
```

### onlyCollectionDeveloper

```solidity
modifier onlyCollectionDeveloper(address collection)
```

