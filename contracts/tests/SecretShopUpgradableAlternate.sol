// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import '../secretShop/SecretShopUpgradable.sol';
import '../secretShop/interfaces/IWETHUpgradable.sol';

contract SecretShopUpgradableAlternative is SecretShopUpgradable {
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
    require(msg.sender == address(this), 'SecretShop: unsafe call');
    // force to revert
    revert();
  }
}
