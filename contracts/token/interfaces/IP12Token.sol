// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

interface IP12Token {
  function mint(address recipient, uint256 amount) external;

  function maxSupply() external returns (uint256);
}
