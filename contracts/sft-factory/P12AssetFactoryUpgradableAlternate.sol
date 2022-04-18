// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import './P12AssetFactoryUpgradable.sol';

contract P12AssetFactoryUpgradableAlternative is P12AssetFactoryUpgradable {
  string public name;

  function setName(string memory _name) public {
    name = _name;
  }

  function getName() public view returns (string memory) {
    return name;
  }
}
