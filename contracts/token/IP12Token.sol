// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IP12Token is IERC20 {
  function mint(address recipient, uint256 amount) external;
}
