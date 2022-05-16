// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../factory/P12V0FactoryUpgradeable.sol';

// new contract for test
contract P12V0FactoryUpgradeableAlter is P12V0FactoryUpgradeable {
  /**
   * @dev set UniswapFactory address
   * @param newAddr new UniswapFactory address
   */
  function setUniswapFactory(address newAddr) public onlyOwner {
    uniswapFactory = newAddr;
  }

  /**
   * @dev set Uniswap Router Address
   * @param newAddr new Uniswap Router Address
   */
  function setUniswapRouter(address newAddr) public onlyOwner {
    uniswapRouter = newAddr;
  }

  /**
   * @dev this is used for test internal function upgrade
   */
  function compareStrings(string memory, string memory) internal pure override returns (bool) {
    return true;
  }

  /**
   * @dev public function to call internal function
   */
  function callWhiteBlack() public {
    require(compareStrings('1', '2'), 'callWhiteBlack fail');
  }
}
