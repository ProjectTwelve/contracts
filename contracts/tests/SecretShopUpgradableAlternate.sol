// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import '../secretShop/SecretShopUpgradable.sol';

contract SecretShopUpgradableAlternative is SecretShopUpgradable {
  string public name;

  function setName(string memory _name) public {
    name = _name;
  }

  function getName() public view returns (string memory) {
    return name;
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
