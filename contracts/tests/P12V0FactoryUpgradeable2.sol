// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '../factory/P12V0FactoryUpgradeable.sol';

// new contract for test
contract P12V0FactoryUpgradeable2 is P12V0FactoryUpgradeable {
  function setUniswapFactory(address newAddr) public onlyOwner {
    uniswapFactory = newAddr;
  }

  function setUniswapRouter(address newAddr) public onlyOwner {
    uniswapRouter = newAddr;
  }
}
