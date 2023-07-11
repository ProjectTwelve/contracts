// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { Vm } from 'forge-std/Vm.sol';
import 'test/UniswapV3Deployer.sol';
import { P12Token } from 'src/token/P12Token.sol';
import { P12CoinFactoryUpgradeable } from 'src/coinFactory/P12CoinFactoryUpgradeable.sol';
import { IUniswapV3Factory } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import { INonfungiblePositionManager } from 'src/interfaces/external/uniswap/INonfungiblePositionManager.sol';

import 'forge-std/Test.sol';

contract AllTestBase is Test {
  address _owner = vm.addr(12);

  function setUp() public {}

  function testDeployAll() public {
    // deploy uniswap
    address v3Factory = UniswapV3Deployer.deployUniswapV3Factory();
    address WETH9 = UniswapV3Deployer.deployWETH9();
    address v3Router = UniswapV3Deployer.deployUniswapV3Router(v3Factory, WETH9);
    address nftPosDes = UniswapV3Deployer.deployNFTPositionDescriptor(WETH9, 'P12');
    address nftPos = UniswapV3Deployer.deployPosManager(v3Factory, WETH9, nftPosDes);

    // deploy p12
    address p12 = address(new P12Token(_owner, 'Project Twleve', 'P12', UINT256_MAX));

    // deploy coinfactory
    P12CoinFactoryUpgradeable coinFactory = new P12CoinFactoryUpgradeable();
    coinFactory.initialize(_owner, p12, IUniswapV3Factory(v3Factory), INonfungiblePositionManager(nftPos));
  }
}
