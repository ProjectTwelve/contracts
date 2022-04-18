pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './IP12Token.sol';

// temporary contract, not corresponding to real token model

contract P12Token is IP12Token, ERC20, Ownable {
  constructor() ERC20('Project Twelve', 'P12') {}

  function mint(address recipient, uint256 amount) public override onlyOwner {
    _mint(recipient, amount);
  }
}
