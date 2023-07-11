// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { Vm } from 'forge-std/Vm.sol';

import 'test/UniswapV3Deployer.sol';

import 'forge-std/Test.sol';

contract AllTestBase is Test {
  function setUp() public {}

  function testDeployAll() public {
    // deploy uniswap
    address v3Factory = UniswapV3Deployer.deployUniswapV3Factory();
    address WETH9 = UniswapV3Deployer.deployWETH9();
    address v3Router = UniswapV3Deployer.deployUniswapV3Router(v3Factory, WETH9);
    address nftPosDes = UniswapV3Deployer.deployNFTPositionDescriptor(WETH9, 'P12');
    address nftPos = UniswapV3Deployer.deployPosManager(v3Factory, WETH9, nftPosDes);

    // vm.readFile()
    // deploy coinfactory
  }
}
