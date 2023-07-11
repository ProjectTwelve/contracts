// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { ERC20BurnableUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import { IP12GameCoin } from './interfaces/IP12GameCoin.sol';
import { ERC20PermitUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol';
import { ERC20BurnableUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import { Ownable2StepUpgradeable } from '@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol';

contract P12GameCoin is ERC20PermitUpgradeable, ERC20BurnableUpgradeable, Ownable2StepUpgradeable, IP12GameCoin {
  /**
   * @dev Off-chain data, game id
   */
  string private _gameId;

  /**
   * @dev game coin's logo
   */
  string private _iconUrl;

  /**
   * @dev override oz erc20 to update both variable
   */
  string private _name;
  string private _symbol;

  /**
   * @param name_ game coin name
   * @param symbol_ game coin symbol
   * @param gameId_ gameId
   * @param iconUrl_ game coin icon's url
   */
  function initialize(
    address owner_,
    string memory name_,
    string memory symbol_,
    string memory gameId_,
    string memory iconUrl_
  ) public override {
    _name = name_;
    _symbol = symbol_;
    _gameId = gameId_;
    _iconUrl = iconUrl_;

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
   * @param recipient address which receive the coin, usually be custodian address
   * @param account off-chain account
   * @param amount amount of this transfer
   */
  function transferWithAccount(address recipient, string memory account, uint256 amount) external override {
    transfer(recipient, amount);
    emit TransferWithAccount(recipient, account, amount);
  }

  /**
   * @dev set new Icon Url
   */
  function setGameCoinIconUrl(string calldata newUrl) external override onlyOwner {
    string memory oldUrl = _iconUrl;
    _iconUrl = newUrl;
    emit IconUrlUpdated(oldUrl, newUrl);
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the gameId of the token
   */
  function gameId() public view virtual override returns (string memory) {
    return _gameId;
  }

  /**
   * @dev Returns the icon url of the token
   */
  function gameCoinIconUrl() public view virtual override returns (string memory) {
    return _iconUrl;
  }
}
