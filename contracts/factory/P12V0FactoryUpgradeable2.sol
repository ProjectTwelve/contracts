// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './P12V0FactoryUpgradeable.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IP12V0Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import '../libraries/FullMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './P12V0ERC20.sol';

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
