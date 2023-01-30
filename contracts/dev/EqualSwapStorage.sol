// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import { IERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

contract EqualSwapStorage {
  IERC20Upgradeable public erc20;

  uint256[49] private _gap;
}
