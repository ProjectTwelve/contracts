// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import '../access/SafeOwnable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IP12RewardVault.sol';
import '../token/interfaces/IP12Token.sol';

contract P12RewardVault is SafeOwnable, IP12RewardVault {
  using SafeERC20 for IERC20;

  IP12Token public p12Token;

  constructor(IP12Token p12Token_) {
    p12Token = p12Token_;
  }

  /**
    @notice Send reward to user
    @param to The address of awards 
    @param amount number of awards 
   */
  function reward(address to, uint256 amount) external virtual override onlyOwner {
    IERC20(address(p12Token)).safeTransfer(to, amount);
  }
}
