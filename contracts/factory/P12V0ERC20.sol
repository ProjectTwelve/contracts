// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import './interfaces/IP12V0ERC20.sol';

contract P12V0ERC20 is IP12V0ERC20, ERC20, ERC20Burnable, Ownable {
  string private _gameId;
  string private _gameCoinIconUrl;

  event TransferWithAccount(address recipient, string account, uint256 amount);

  constructor(
    string memory name_,
    string memory symbol_,
    string memory gameId_,
    string memory gameCoinIconUrl_,
    uint256 amount
  ) ERC20(name_, symbol_) {
    _gameId = gameId_;
    _gameCoinIconUrl = gameCoinIconUrl_;
    _mint(msg.sender, amount);
  }

  function mint(address to, uint256 amount) public override onlyOwner {
    _mint(to, amount);
  }

  function gameId() external view override returns (string memory) {
    return _gameId;
  }

  function gameCoinIconUrl() external view override returns (string memory) {
    return _gameCoinIconUrl;
  }

  function transferWithAccount(
    address recipient,
    string memory account,
    uint256 amount
  ) external override {
    transfer(recipient, amount);
    emit TransferWithAccount(recipient, account, amount);
  }
}
