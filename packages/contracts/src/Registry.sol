// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { IRegistry } from 'src/IRegistry.sol';

import { Ownable2Step } from '@openzeppelin/contracts/access/Ownable2Step.sol';

contract Registry is IRegistry, Ownable2Step {
  event AddressRegistered(bytes32 indexed key, address indexed addr);
  mapping(bytes32 => address) public override addressRegistry;

  constructor(address owner_) {
    _transferOwnership(owner_);
  }

  function registerAddress(bytes32 key, address addr) external override onlyOwner {
    addressRegistry[key] = addr;
    emit AddressRegistered(key, addr);
  }
}
