// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import '../sft-factory/P12AssetFactoryUpgradable.sol';

contract P12AssetFactoryUpgradableAlternative is P12AssetFactoryUpgradable {
  string public name;

  function setName(string memory _name) public {
    name = _name;
  }

  function getName() public view returns (string memory) {
    return name;
  }
}
