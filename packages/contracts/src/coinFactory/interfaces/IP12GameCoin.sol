// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { IERC1046 } from 'src/coinFactory/interfaces/IERC1046.sol';

interface IP12GameCoin is IERC1046 {
  /**
   * @dev record the event that transfer coin with a off-chain account, which will be used when someone want to deposit his coin to off-chain game.
   */
  event TransferWithAccount(address recipient, string account, uint256 amount);

  event NameUpdated(string oldName, string newName);

  event SymbolUpdated(string oldSymbol, string newSymbol);

  function mint(address to, uint256 amount) external;

  function gameId() external view returns (uint256);

  function transferWithAccount(address recipient, string memory account, uint256 amount) external;

  function initialize(
    address owner_,
    string calldata name_,
    string calldata symbol_,
    string calldata uri_,
    uint256 gameId_
  ) external;
}
