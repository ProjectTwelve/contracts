// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IP12RewardVault {
  function reward(address to, uint256 amount) external;
}

contract P12RewardVault is Ownable {
  using SafeERC20 for IERC20;

  address public P12Token;

  constructor(address _P12Token) public {
    P12Token = _P12Token;
  }

  //send reward
  function reward(address to, uint256 amount) external onlyOwner {
    IERC20(P12Token).safeTransfer(to, amount);
  }
}
