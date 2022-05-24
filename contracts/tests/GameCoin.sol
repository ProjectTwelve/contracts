// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../utils/TwoStepOwnable.sol';

pragma solidity 0.8.13;

contract GameCoin is ERC20, TwoStepOwnable {
  constructor(
    string memory name,
    string memory symbol,
    uint256 totalSupply
  ) ERC20(name, symbol) {
    _mint(msg.sender, totalSupply);
  }

  function mint(address account, uint256 amount) public onlyOwner returns (bool) {
    _mint(account, amount);
    return true;
  }
}
