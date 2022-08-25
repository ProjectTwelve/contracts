## P12Asset

### contractURI

```solidity
string contractURI
```

_contract-level metadata uri, refer to https://docs.opensea.io/docs/contract-level-metadata_

### supply

```solidity
mapping(uint256 => uint256) supply
```

_current supply, how many a id are minted not._

### maxSupply

```solidity
mapping(uint256 => uint256) maxSupply
```

_max supply, a token id has a max supply cap_

### idx

```solidity
uint256 idx
```

_token id index, which will increase one by one_

### \_balances

```solidity
mapping(uint256 => mapping(address => uint256)) _balances
```

### \_uri

```solidity
mapping(uint256 => string) _uri
```

### constructor

```solidity
constructor(string contractURI_) public
```

### create

```solidity
function create(uint256 amount, string newUri) public returns (uint256)
```

_developer create an new asset_

| Name   | Type    | Description                 |
| ------ | ------- | --------------------------- |
| amount | uint256 | the new asset's totalSupply |
| newUri | string  | metadata uri of the asset   |

| Name | Type    | Description                 |
| ---- | ------- | --------------------------- |
| [0]  | uint256 | uint256 new asset's tokenId |

### setUri

```solidity
function setUri(uint256 id, string newUri) public
```

_update token's metadata uri_

| Name   | Type    | Description |
| ------ | ------- | ----------- |
| id     | uint256 | tokenId     |
| newUri | string  | new uri     |

### mint

```solidity
function mint(address to, uint256 id, uint256 amount, bytes data) public
```

See {\_mint}.

### uri

```solidity
function uri(uint256 id) public view virtual returns (string)
```

_return token metadata uri_

| Name | Type    | Description |
| ---- | ------- | ----------- |
| id   | uint256 | token's id  |

| Name | Type   | Description      |
| ---- | ------ | ---------------- |
| [0]  | string | uri metadata uri |

### setContractURI

```solidity
function setContractURI(string newContractURI) public
```

_set contract-level MetaData_

| Name           | Type   | Description                     |
| -------------- | ------ | ------------------------------- |
| newContractURI | string | new Contract-level metadata uri |

### \_setUri

```solidity
function _setUri(uint256 id, string newUri) private
```

_set token metadata uri_

| Name   | Type    | Description  |
| ------ | ------- | ------------ |
| id     | uint256 | token id     |
| newUri | string  | metadata uri |
