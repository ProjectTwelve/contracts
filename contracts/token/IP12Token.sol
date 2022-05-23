// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IP12Token is IERC20 {
  function mint(address recipient, uint256 amount) external;
}
