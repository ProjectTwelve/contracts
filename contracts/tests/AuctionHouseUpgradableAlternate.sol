// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import '../auctionHouse/AuctionHouseUpgradable.sol';

contract AuctionHouseUpgradableAlternative is AuctionHouseUpgradable {
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
  function run1(
    Market.Order memory order,
    Market.SettleShared memory shared,
    Market.SettleDetail memory detail
  ) external virtual override returns (uint256) {
    require(msg.sender == address(this), 'AuctionHouse: unsafe call');
    // force to revert
    revert();

    // return _run(order, shared, detail);
  }
}
