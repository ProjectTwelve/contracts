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
  string private _gameId;

  /**
   * @dev game coin's logo
   */
  string private _gameCoinIconUrl;

  /**
   * @dev record the event that transfer coin with a off-chain account, which will be used when someone want to deposit his coin to off-chain game.
   */
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

  /**
   * @dev mint function, the Owner will only be factory contract
   */
  function mint(address to, uint256 amount) public override onlyOwner {
    _mint(to, amount);
  }

  /**
   * @return string off-chain game id
   */
  function gameId() external view override returns (string memory) {
    return _gameId;
  }

  /**
   * @return string game coin logo url
   */
  function gameCoinIconUrl() external view override returns (string memory) {
    return _gameCoinIconUrl;
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
