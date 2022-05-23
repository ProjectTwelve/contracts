// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './IP12Token.sol';

// temporary contract, not corresponding to real token model

contract P12Token is IP12Token, ERC20, Ownable {
  constructor(
    string memory name,
    string memory symbol,
    uint256 totalSupply
  ) ERC20(name, symbol) {
    _mint(msg.sender, totalSupply);
  }

  function mint(address recipient, uint256 amount) public override onlyOwner {
    _mint(recipient, amount);
  }
}
