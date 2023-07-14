// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.19;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { ERC20Permit } from '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import { Ownable2Step } from '@openzeppelin/contracts/access/Ownable2Step.sol';
import './interfaces/IP12Token.sol';

// temporary contract, not corresponding to real token model

contract P12Token is IP12Token, ERC20Permit, Ownable2Step {
  error SupplyExceedMax();

  uint256 public immutable override maxSupply;

  constructor(
    address owner_,
    string memory name,
    string memory symbol,
    uint256 maxSupply_
  ) ERC20(name, symbol) ERC20Permit(name) {
    maxSupply = maxSupply_;
    _transferOwnership(owner_);
  }

  function mint(address recipient, uint256 amount) public override onlyOwner {
    _mint(recipient, amount);
    if (totalSupply() > maxSupply) revert SupplyExceedMax();
  }
}
