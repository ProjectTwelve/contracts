// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import './P12ExchangeUpgradable.sol';

contract P12ExchangeUpgradableAlternative is P12ExchangeUpgradable {
  string public name;

  function setName(string memory _name) public {
    name = _name;
  }

  function getName() public view returns (string memory) {
    return name;
  }
}
