// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
    uint256 amount_
  ) ERC20(name_, symbol_) {
    gameId = gameId_;
    gameCoinIconUrl = gameCoinIconUrl_;
    _mint(msg.sender, amount_);
  }

  /**
   * @dev mint function, the Owner will only be factory contract
   * @param to address which receive newly-minted coin
   * @param amount amount of the minting
   */
  function mint(address to, uint256 amount) public override onlyOwner {
    _mint(to, amount);
  }

  /**
   * @dev transfer function for just a basic transfer with an off-chain account
   * @dev called when a user want to deposit his coin from on-chain to off-chain
   * @param recipient address which receive the coin, usually be custodian address
   * @param account off-chain account
   * @param amount amount of this transfer
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
