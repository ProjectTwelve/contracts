// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../access/SafeOwnable.sol';

import './interfaces/IP12Token.sol';

// temporary contract, not corresponding to real token model

contract P12Token is IP12Token, ERC20, SafeOwnable {
  error SupplyExceedMax();

  uint256 public immutable override maxSupply;

  constructor(
    address owner_,
    string memory name,
    string memory symbol,
    uint256 maxSupply_
  ) ERC20(name, symbol) SafeOwnable(owner_) {
    maxSupply = maxSupply_;
  }

  function mint(address recipient, uint256 amount) public override onlyOwner {
    _mint(recipient, amount);
    if (totalSupply() > maxSupply) revert SupplyExceedMax();
  }
}
