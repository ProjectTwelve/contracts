// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import '../coinFactory/P12CoinFactoryUpgradeable.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

// new contract for test
contract P12CoinFactoryUpgradeableAlter is P12CoinFactoryUpgradeable {
  error CallWhiteBlackFail();

  /**
   * @dev set UniswapFactory address
   * @param newAddr new UniswapFactory address
   */
  function setUniswapFactory(IUniswapV2Factory newAddr) public override onlyOwner {
    uniswapFactory = IUniswapV2Factory(newAddr);
  }

  /**
   * @dev set Uniswap Router Address
   * @param newAddr new Uniswap Router Address
   */
  function setUniswapRouter(IUniswapV2Router02 newAddr) public override onlyOwner {
    uniswapRouter = IUniswapV2Router02(newAddr);
  }

  /**
   * @dev this is used for test internal function upgrade
   */
  function _compareStrings(string memory, string memory) internal pure override returns (bool) {
    return true;
  }

  /**
   * @dev public function to call internal function
   */
  function callWhiteBlack() public pure {
    if (!_compareStrings('1', '2')) revert CallWhiteBlackFail();
  }
}
