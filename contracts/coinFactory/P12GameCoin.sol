// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../access/SafeOwnable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import './interfaces/IP12GameCoin.sol';

contract P12GameCoin is IP12GameCoin, ERC20, ERC20Burnable, SafeOwnable {
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
   * @param amount_ amount of first minting
   */
  constructor(
    address owner_,
    string memory name_,
    string memory symbol_,
    string memory gameId_,
    string memory iconUrl_,
    uint256 amount_
  ) ERC20(name_, symbol_) SafeOwnable(owner_) {
    _name = name_;
    _symbol = symbol_;
    _gameId = gameId_;
    _iconUrl = iconUrl_;
    _mint(msg.sender, amount_);
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
  function transferWithAccount(
    address recipient,
    string memory account,
    uint256 amount
  ) external override {
    transfer(recipient, amount);
    emit TransferWithAccount(recipient, account, amount);
  }

  /**
   * @dev set new name
   */
  function setName(string calldata newName) external override onlyOwner {
    string memory oldName = _name;
    _name = newName;
    emit NameUpdated(oldName, newName);
  }

  /**
   * @dev set new symbol
   */
  function setSymbol(string calldata newSymbol) external override onlyOwner {
    string memory oldSymbol = _symbol;
    _symbol = newSymbol;
    emit SymbolUpdated(oldSymbol, newSymbol);
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
