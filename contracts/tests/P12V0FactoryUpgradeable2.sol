// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../factory/P12V0FactoryUpgradeable.sol';

// new contract for test
contract P12V0FactoryUpgradeable2 is P12V0FactoryUpgradeable {
  string public name;

  function setName(string memory _name) public {
    name = _name;
  }

  function getName() public view returns (string memory) {
    return name;
  }
}
