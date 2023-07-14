// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { ERC20BurnableUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import { IP12GameCoin } from './interfaces/IP12GameCoin.sol';
import { ERC20PermitUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol';
import { ERC20BurnableUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import { Ownable2StepUpgradeable } from '@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol';

contract P12GameCoin is ERC20PermitUpgradeable, ERC20BurnableUpgradeable, Ownable2StepUpgradeable, IP12GameCoin {
  /**
   * @dev Off-chain game id
   */
  uint256 private _gameId;
  string private _uri;

  /**
   * @param name_ game coin name
   * @param symbol_ game coin symbol
   * @param gameId_ gameId
   */
  function initialize(
    address owner_,
    string calldata name_,
    string calldata symbol_,
    string calldata uri_,
    uint256 gameId_
  ) public override initializer {
    _gameId = gameId_;
    _uri = uri_;

    __ERC20Permit_init(name_);
    __ERC20_init(name_, symbol_);
    __Ownable2Step_init();
    _transferOwnership(owner_);
  }

  /**
   * @dev mint function, the Owner will only be factory contract
   * @param to address which receive newly-minted coin
   * @param amount amount of the minting
   */
  function mint(address to, uint256 amount) external override onlyOwner {
    _mint(to, amount);
  }

  /**
   * @dev transfer function for just a basic transfer with an off-chain account
   * @dev called when a user want to deposit his coin from on-chain to off-chain
   * @notice deposit is valid only when recipient is on-chain custodian address
   * @param recipient address which receive the coin, usually be custodian address
   * @param account off-chain account hash
   * @param amount amount of this transfer
   */
  function depositToAccount(address recipient, uint256 amount, bytes32 account) external override {
    transfer(recipient, amount);
    emit DepositToAccount(recipient, account, amount);
  }

  /**
   * @dev return token uri
   */
  function tokenURI() public view returns (string memory) {
    return _uri;
  }

  /**
   * @dev Returns the gameId of the token
   */
  function gameId() public view virtual override returns (uint256) {
    return _gameId;
  }
}
