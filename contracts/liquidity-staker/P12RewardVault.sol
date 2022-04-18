pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import { Ownable } from './lib/Ownable.sol';
import { SafeERC20 } from './lib/SafeERC20.sol';
import { IERC20 } from './interfaces/IERC20.sol';

interface IP12RewardVault {
  function reward(address to, uint256 amount) external;
}

contract P12RewardVault is Ownable {
  using SafeERC20 for IERC20;

  address public P12Token;

  constructor(address _P12Token) public {
    P12Token = _P12Token;
  }

  function reward(address to, uint256 amount) external onlyOwner {
    IERC20(P12Token).safeTransfer(to, amount);
  }
}
