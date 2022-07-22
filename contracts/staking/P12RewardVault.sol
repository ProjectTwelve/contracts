// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

import '../access/SafeOwnable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IP12RewardVault.sol';
import '../token/interfaces/IP12Token.sol';

contract P12RewardVault is SafeOwnable, IP12RewardVault {
  using SafeERC20 for IERC20;

  address public p12Token;

  constructor(address p12Token_) {
    require(p12Token_ != address(0), 'P12RV: address cannot be 0');
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

  /**
    @notice withdraw token Emergency
   */
  function withdrawEmergency(address to) external virtual override onlyOwner {
    require(to != address(0), 'P12RV: address cannot be 0');
    IERC20(p12Token).safeTransfer(to, IERC20(p12Token).balanceOf(address(this)));
    emit WithdrawEmergency(p12Token, IERC20(p12Token).balanceOf(address(this)));
  }
}
