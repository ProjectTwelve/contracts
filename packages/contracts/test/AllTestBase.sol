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
  address _v3Factory;
  address _weth9;
  address _v3router;
  address _nftPos;
  address _p12;
  IP12CoinFactoryUpgradeable _coinFactory;

  function setUp() public virtual {
    // use fork network to avoid manual deployment
    string memory MAINNET_RPC_URL = vm.envString('ETH_CHAIN_RPC_URL');
    _ethFork = vm.createSelectFork(MAINNET_RPC_URL, 17683004);
    mockDeployAll();
  }

  function testDeployAll() public {
    mockDeployAll();
  }

  function mockDeployAll() public {
    // deploy uniswap
    // _v3Factory = UniswapV3Deployer.deployUniswapV3Factory();
    // _weth9 = UniswapV3Deployer.deployWETH9();
    // _v3router = UniswapV3Deployer.deployUniswapV3Router(_v3Factory, _weth9);
    // address nftPosDes = UniswapV3Deployer.deployNFTPositionDescriptor(_weth9, 'P12');
    // _nftPos = UniswapV3Deployer.deployPosManager(_v3Factory, _weth9, nftPosDes);

    // https://github.com/Uniswap/v3-periphery/blob/main/deploys.md
    _v3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    _weth9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    _v3router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    _nftPos = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    // deploy p12
    _p12 = address(new P12Token(_owner, 'Project Twleve', 'P12', UINT256_MAX));

    // deploy game coin impl
    address gameCoinImpl = address(new P12GameCoin());
    // deploy coinfactory
    P12CoinFactoryUpgradeable coinFactory = new P12CoinFactoryUpgradeable();
    coinFactory.initialize(_owner, _p12, IUniswapV3Factory(_v3Factory), INonfungiblePositionManager(_nftPos), gameCoinImpl);
    _coinFactory = IP12CoinFactoryUpgradeable(coinFactory);
  }
}
