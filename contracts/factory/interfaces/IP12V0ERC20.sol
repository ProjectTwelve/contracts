// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IP12V0ERC20 {
  function mint(address to, uint256 amount) external;

  function gameId() external view returns (string memory);

  function gameCoinIconUrl() external view returns (string memory);

  function transferWithAccount(
    address recipient,
    string memory account,
    uint256 amount
  ) external;
}
