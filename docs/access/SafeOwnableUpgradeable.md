## SafeOwnableUpgradeable

### \_owner

```solidity
address _owner
```

### \_pendingOwner

```solidity
address _pendingOwner
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address previousOwner, address newOwner)
```

### \_\_Ownable_init

```solidity
function __Ownable_init() internal
```

_Initializes the contract setting the deployer as the initial owner._

### \_\_Ownable_init_unchained

```solidity
function __Ownable_init_unchained() internal
```

### owner

```solidity
function owner() public view virtual returns (address)
```

_Returns the address of the current owner._

### pendingOwner

```solidity
function pendingOwner() public view virtual returns (address)
```

_Return the address of the pending owner_

### onlyOwner

```solidity
modifier onlyOwner()
```

_Throws if called by any account other than the owner._

### renounceOwnership

```solidity
function renounceOwnership() public virtual
```

\_Leaves the contract without owner. It will not be possible to call
`onlyOwner` functions anymore. Can only be called by the current owner.

NOTE: Renouncing ownership will leave the contract without an owner,
thereby removing any functionality that is only available to the owner.\_

### transferOwnership

```solidity
function transferOwnership(address newOwner, bool direct) public virtual
```

_Transfers ownership of the contract to a new account (`newOwner`).
Can only be called by the current owner.
Note If direct is false, it will set an pending owner and the OwnerShipTransferring
only happens when the pending owner claim the ownership_

### claimOwnership

```solidity
function claimOwnership() public
```

_pending owner call this function to claim ownership_

### \_transferOwnership

```solidity
function _transferOwnership(address newOwner) internal virtual
```

_Transfers ownership of the contract to a new account (`newOwner`).
Internal function without access restriction._

### \_transferPendingOwnership

```solidity
function _transferPendingOwnership(address newOwner) internal virtual
```

_set the pending owner address
Internal function without access restriction._

### \_claimOwnership

```solidity
function _claimOwnership() internal virtual
```

_Transfers ownership of the contract to a new account (`newOwner`).
Internal function without access restriction._

### \_\_gap

```solidity
uint256[48] __gap
```

_This empty reserved space is put in place to allow future versions to add new
variables without shifting down storage in the inheritance chain.
See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps_
