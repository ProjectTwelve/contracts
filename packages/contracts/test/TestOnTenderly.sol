// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import 'forge-std/Script.sol';

import 'src/coinFactory/P12CoinFactoryUpgradeable.sol';

import { P12Token } from 'src/token/P12Token.sol';

contract TestOnTenderly is Script {
  uint256 _ethFork;
  address _owner = 0x4A0bB26Cdf9107033117e96eD3e2CE7Fa2ffbD87;
  address _v3Factory;
  address _weth9;
  address _v3router;
  address _nftPos;
  address _p12;
  IP12CoinFactoryUpgradeable _coinFactory;

  function run() public {
    vm.startBroadcast();

    mockDeployAll();

    string memory gameId = '1';
    // tmp private key
    // 564285758b2888408bad2ce9785e239ca8ce9e88c3d32b2128ececaefdfbf310
    // 0x4A0bB26Cdf9107033117e96eD3e2CE7Fa2ffbD87

    // mock register
    _coinFactory.setDev(0x4A0bB26Cdf9107033117e96eD3e2CE7Fa2ffbD87);
    _coinFactory.register(gameId, 0x4A0bB26Cdf9107033117e96eD3e2CE7Fa2ffbD87);

    address gameDev = _coinFactory.getGameDev(gameId);

    uint256 amountGameCoin = 1_000_000 ether;

    // just test as 1:1 price
    uint256 amountP12 = amountGameCoin / 2;
    uint160 priceSqrt = 1 * 2 ** 96;

    IERC20Upgradeable(_p12).approve(address(_coinFactory), UINT256_MAX);
    // address gameCoin = _coinFactory.create('test game coin', 'tgc', gameId, '', amountGameCoin, amountP12, priceSqrt);

    vm.stopBroadcast();
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

    P12Token(_p12).mint(0x4A0bB26Cdf9107033117e96eD3e2CE7Fa2ffbD87, type(uint128).max);

    // deploy game coin impl
    address gameCoinImpl = address(new P12GameCoin());
    // deploy coinfactory
    P12CoinFactoryUpgradeable coinFactory = new P12CoinFactoryUpgradeable();
    coinFactory.initialize(_owner, _p12, IUniswapV3Factory(_v3Factory), INonfungiblePositionManager(_nftPos), gameCoinImpl);
    _coinFactory = IP12CoinFactoryUpgradeable(coinFactory);
  }
}
