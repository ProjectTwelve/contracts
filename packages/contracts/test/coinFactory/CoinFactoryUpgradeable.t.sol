// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { IUniswapV3Factory } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import { INonfungiblePositionManager } from 'src/interfaces/external/uniswap/INonfungiblePositionManager.sol';

import '@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol';
import 'test/AllTestBase.sol';
import 'forge-std/Test.sol';
import 'src/coinFactory/P12CoinFactoryUpgradeable.sol';
import 'src/staking/interfaces/IP12MineUpgradeable.sol';

import 'src/staking/interfaces/IGaugeController.sol';
import 'src/coinFactory/interfaces/IP12GameCoin.sol';
import 'src/token/P12Token.sol';

contract CoinFactoryUpgradeableTest is AllTestBase {
  function setUp() public override {
    super.setUp();
  }

  // function testSetDev(address newDev) public {
  //   vm.prank(_coinFactory.owner());
  //   _coinFactory.setDev(newDev);
  //   assertEq(_coinFactory.dev(), newDev);
  // }

  // function testSetP12Mine(IP12MineUpgradeable newP12Mine) public {
  //   vm.prank(_coinFactory.owner());
  //   _coinFactory.setP12Mine(newP12Mine);
  //   assertEq(_coinFactory.p12Mine.address, address(newP12Mine));
  // }

  // function testSetGaugeController(IGaugeController newGaugeController) public {
  //   vm.prank(_coinFactory.owner());
  //   _coinFactory.setGaugeController(newGaugeController);
  //   assertEq(_coinFactory.gaugeController.address, address(newGaugeController));
  // }

  // function testSetP12Token(address NewP12Token) public {
  //   vm.prank(_coinFactory.owner());
  //   _coinFactory.setP12Token(NewP12Token);
  //   assertEq(_coinFactory.p12(), NewP12Token);
  // }

  // function testSetUniswapFactory(IUniswapV3Factory NewUniswapFactory) public {
  //   vm.prank(_coinFactory.owner());
  //   _coinFactory.setUniswapFactory(NewUniswapFactory);
  //   assertEq(_coinFactory.uniswapFactory.address, address(NewUniswapFactory));
  // }

  // function testSetUniswapRouter(INonfungiblePositionManager newPosManager_) public {
  //   vm.prank(_coinFactory.owner());

  //   _coinFactory.setUniswapPosManager(newPosManager_);
  //   assertEq(_coinFactory.uniswapPosManager.address, address(newPosManager_));
  // }

  function testRegister(uint256 gameId, address developer) public {
    vm.assume(developer != address(0));

    this.mockRegister(gameId, developer);
    assertEq(_coinFactory.getGameDev(gameId), developer);
  }

  function mockRegister(uint256 gameId, address developer) public {
    vm.prank(_coinFactory.getGameDev(gameId));
    _coinFactory.register(gameId, developer);
  }

  function testCreateGameCoin() public {
    //
    string memory name;
    string memory symbol;
    uint256 gameId;
    string memory gameCoinIconUrl;
    address developer = address(113);
    uint96 amountGameCoin = 10000 ether;
    // vm.assume(developer != address(0) && amountGameCoin > 100_000);

    // mock register
    mockRegister(gameId, developer);

    address gameDev = _coinFactory.getGameDev(gameId);

    deal(_p12, gameDev, UINT256_MAX);

    // just test as 1:1 price
    uint256 amountP12 = amountGameCoin / 2;
    uint160 priceSqrt = 1 * 2 ** 96;
    vm.startPrank(gameDev);
    IERC20Upgradeable(_p12).approve(address(_coinFactory), UINT256_MAX);
    address gameCoin = _coinFactory.create(name, symbol, gameId, amountGameCoin, amountP12, priceSqrt);
    assertEq(IERC20Upgradeable(address(gameCoin)).balanceOf(address(_coinFactory)), amountGameCoin / 2);
  }

  // function testQueueMintCoin(string memory gameId, address gameCoinAddress, uint256 amountGameCoin) public {
  //   vm.prank(p12CoinFactoryUpgradeable.allGames(gameId));
  //   bool status = p12CoinFactoryUpgradeable.queueMintCoin(gameId, gameCoinAddress, amountGameCoin);
  //   assertTrue(status);
  // }

  // function testExecuteMintCoin(address gameCoinAddress, bytes32 mintId) public {
  //   uint256 oldBalance = IERC20Upgradeable(gameCoinAddress).balanceOf(address(p12CoinFactoryUpgradeable));
  //   bool status = p12CoinFactoryUpgradeable.executeMintCoin(gameCoinAddress, mintId);
  //   assertTrue(status);
  //   uint256 Balance = IERC20Upgradeable(gameCoinAddress).balanceOf(address(p12CoinFactoryUpgradeable));
  //   assertGt(Balance, oldBalance);
  // }

  // function testWithdraw(address userAddress, address gameCoinAddress, uint256 amountGameCoin) public {
  //   vm.prank(p12CoinFactoryUpgradeable.dev());
  //   p12CoinFactoryUpgradeable.withdraw(userAddress, gameCoinAddress, amountGameCoin);
  //   uint256 balanceOf = IERC20Upgradeable(gameCoinAddress).balanceOf(userAddress);
  //   assertEq(amountGameCoin, balanceOf);
  // }

  // function testPause() public {
  //   vm.prank(p12CoinFactoryUpgradeable.owner());
  //   p12CoinFactoryUpgradeable.pause();
  // }

  // function testUnpause() public {
  //   vm.prank(p12CoinFactoryUpgradeable.owner());
  //   p12CoinFactoryUpgradeable.unpause();
  // }

  // function testSetDelayK(uint256 newDelayK) public {
  //   vm.prank(p12CoinFactoryUpgradeable.owner());
  //   p12CoinFactoryUpgradeable.setDelayK(newDelayK);
  //   assertEq(p12CoinFactoryUpgradeable.delayK(), newDelayK);
  // }

  // function testSetDelayB(uint256 newDelayB) public {
  //   vm.prank(p12CoinFactoryUpgradeable.owner());
  //   p12CoinFactoryUpgradeable.setDelayB(newDelayB);
  //   assertEq(p12CoinFactoryUpgradeable.delayB(), newDelayB);
  // }

  // // function testGetMintFee(IP12GameCoin gameCoinAddress, uint256 amountGameCoin)public{
  // //   p12CoinFactoryUpgradeable.getMintFee(gameCoinAddress, amountGameCoin);
  // // }

  // function testGetMintDelay(address gameCoinAddress, uint256 amountGameCoin) public {
  //   uint256 timeA = p12CoinFactoryUpgradeable.getMintDelay(gameCoinAddress, amountGameCoin);
  //   uint256 timeB = (amountGameCoin * p12CoinFactoryUpgradeable.delayK()) /
  //     (IERC20Upgradeable(gameCoinAddress).totalSupply()) +
  //     p12CoinFactoryUpgradeable.delayB();
  //   assertEq(timeA, timeB);
  // }
}
