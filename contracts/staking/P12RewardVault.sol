// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import '../access/TwoStepOwnable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IP12RewardVault.sol';

contract P12RewardVault is TwoStepOwnable, IP12RewardVault {
  using SafeERC20 for IERC20;

  address public p12Token;

  constructor(address p12Token_) {
    p12Token = p12Token_;
  }

  /**
    @notice Send reward to user
    @param to The address of awards 
    @param amount number of awards 
   */
  function reward(address to, uint256 amount) external virtual override onlyOwner {
    IERC20(p12Token).safeTransfer(to, amount);
  }
}
