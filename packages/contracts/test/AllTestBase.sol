// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { Vm } from 'forge-std/Vm.sol';
import 'test/UniswapV3Deployer.sol';
import { P12Token } from 'src/token/P12Token.sol';
import 'src/coinFactory/P12CoinFactoryUpgradeable.sol';
import { P12GameCoin } from 'src/coinFactory/P12GameCoin.sol';
import { IUniswapV3Factory } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import { INonfungiblePositionManager } from 'src/interfaces/external/uniswap/INonfungiblePositionManager.sol';

import 'forge-std/Test.sol';

contract AllTestBase is Test {
  uint256 _ethFork;
  address _owner = vm.addr(12);
  address _signer = vm.addr(13);
  address _mockDeveloper = vm.addr(14);
  uint256 _mockGameId = 12;
  address _v3Factory;
  address _weth9;
  address _v3router;
  address _nftPos;
  address _p12;
  IP12CoinFactoryUpgradeable _coinFactory;

  function setUp() public virtual {
    mockDeployAll();
  }

  function testDeployAll() public {
    mockDeployAll();
  }

  function mockDeployAll() public {
    // deploy uniswap
    _v3Factory = UniswapV3Deployer.deployUniswapV3Factory();
    _weth9 = UniswapV3Deployer.deployWETH9();
    _v3router = UniswapV3Deployer.deployUniswapV3Router(_v3Factory, _weth9);
    address nftPosDes = UniswapV3Deployer.deployNFTPositionDescriptor(_weth9, 'P12');
    _nftPos = UniswapV3Deployer.deployPosManager(_v3Factory, _weth9, nftPosDes);

    // deploy p12
    _p12 = address(new P12Token(_owner, 'Project Twelve', 'P12', UINT256_MAX));

    // deploy game coin impl
    address gameCoinImpl = address(new P12GameCoin());
    // deploy coin factory
    P12CoinFactoryUpgradeable coinFactory = new P12CoinFactoryUpgradeable();
    coinFactory.initialize(_owner, _p12, INonfungiblePositionManager(_nftPos), gameCoinImpl);
    _coinFactory = IP12CoinFactoryUpgradeable(coinFactory);

    // set signer
    address[] memory toAddr = new address[](1);
    address[] memory toRemove;
    toAddr[0] = _signer;
    vm.prank(_owner);
    coinFactory.updateSigners(toAddr, toRemove);

    // mock register

    mockRegister(_mockGameId, _mockDeveloper);
  }

  function mockRegister(uint256 gameId, address developer) public {
    vm.prank(_signer);
    _coinFactory.register(gameId, developer);
  }
}
