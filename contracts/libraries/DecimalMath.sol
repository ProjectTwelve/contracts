pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from './SafeMath.sol';

/**
 * @title DecimalMath
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
  using SafeMath for uint256;

  uint256 constant ONE = 10**18;

  function mul(uint256 target, uint256 d) internal pure returns (uint256) {
    return target.mul(d) / ONE;
  }

  function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
    return target.mul(d).divCeil(ONE);
  }

  function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
    return target.mul(ONE).div(d);
  }

  function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
    return target.mul(ONE).divCeil(d);
  }
}
