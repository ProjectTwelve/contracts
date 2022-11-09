// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import '../secretShop/SecretShopUpgradable.sol';
import '../secretShop/interfaces/IWETHUpgradable.sol';

contract SecretShopUpgradableAlter is SecretShopUpgradable {
  function setWETH(IWETHUpgradable newAddr) public onlyOwner {
    weth = newAddr;
  }

  /**
   * @dev override to trigger error
   */
  function runSingle(
    Market.Order memory,
    Market.SettleShared memory,
    Market.SettleDetail memory
  ) external virtual override returns (uint256) {
    if (msg.sender != address(this)) revert UnSafeCall();
    // force to revert
    revert();
  }
}
