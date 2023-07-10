// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import '../coinFactory/P12CoinFactoryUpgradeable.sol';



// new contract for test
contract P12CoinFactoryUpgradeableAlter is P12CoinFactoryUpgradeable {
  error CallWhiteBlackFail();

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
