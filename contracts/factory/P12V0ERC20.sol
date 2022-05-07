// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import './interfaces/IP12V0ERC20.sol';

contract P12V0ERC20 is IP12V0ERC20, ERC20, ERC20Burnable, Ownable {
  /**
   * @dev Off-chain data, game id
   */
  string public override gameId;

  /**
   * @dev game coin's logo
   */
  string public override gameCoinIconUrl;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory gameId_,
    string memory gameCoinIconUrl_,
    uint256 amount
  ) ERC20(name_, symbol_) {
    gameId = gameId_;
    gameCoinIconUrl = gameCoinIconUrl_;
    _mint(msg.sender, amount);
  }

  /**
   * @dev mint function, the Owner will only be factory contract
   */
  function mint(address to, uint256 amount) public override onlyOwner {
    _mint(to, amount);
  }

  /**
   * @dev transfer function for just a basic transfer with an off-chain account
   */
  function transferWithAccount(
    address recipient,
    string memory account,
    uint256 amount
  ) external override {
    transfer(recipient, amount);
    emit TransferWithAccount(recipient, account, amount);
  }
}
