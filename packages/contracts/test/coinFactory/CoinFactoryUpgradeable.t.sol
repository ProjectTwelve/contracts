// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { IUniswapV3Factory } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import { INonfungiblePositionManager } from 'src/interfaces/external/uniswap/INonfungiblePositionManager.sol';

import { IP12CoinFactoryDef } from 'src/coinFactory/interfaces/IP12CoinFactoryUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import 'test/AllTestBase.sol';
import 'forge-std/Test.sol';
import 'src/coinFactory/P12CoinFactoryUpgradeable.sol';
import 'src/staking/interfaces/IP12MineUpgradeable.sol';

import 'src/staking/interfaces/IGaugeController.sol';
import 'src/coinFactory/interfaces/IP12GameCoin.sol';
import 'src/token/P12Token.sol';

contract CoinFactoryUpgradeableTest is AllTestBase, IP12CoinFactoryDef {
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

  function testCreateGameCoin(
    string calldata name,
    string calldata symbol,
    string calldata uri,
    uint256 amountP12Seed,
    uint256 ratioSeed
  ) public {
    //
    uint256 amountP12 = bound(amountP12Seed, 100 ether, 10_000_000_000 ether);
    uint256 ratio = bound(ratioSeed, 1, 1_000_000_000);
    uint256 amountGameCoin = amountP12 * ratio;

    address gameCoin = this.mockCreateGameCoin(name, symbol, uri, amountGameCoin, amountP12);
    // The diff is less than 1/10k
    assertApproxEqRel(IERC20Upgradeable(address(gameCoin)).balanceOf(address(_coinFactory)), amountGameCoin / 2, 1e14);
  }

  function testQueueMintGameCoin(uint256 mintAmount) public {
    address coin = mockCreateRandomGameCoin();

    vm.expectEmit(false, true, true, true);
    emit QueueMintCoin(0, coin, mintAmount, block.timestamp, 0);

    vm.prank(_mockDeveloper);
    _coinFactory.queueMintCoin(coin, mintAmount);
  }

  function testExecuteMintGameCoin() public {
    uint256 mintAmount = 200 ether;
    address coin = mockCreateRandomGameCoin();

    vm.prank(_mockDeveloper);
    bytes32 mintId = _coinFactory.queueMintCoin(coin, mintAmount);

    vm.expectEmit(true, true, true, true);
    emit ExecuteMintCoin(mintId, coin, _mockDeveloper);

    vm.warp(block.timestamp + 1);

    vm.prank(_mockDeveloper);
    _coinFactory.executeMintCoin(mintId);
  }

  function mockCreateRandomGameCoin() public returns (address gameCoin) {
    gameCoin = mockCreateGameCoin('Game Coin', 'GC', 'ipfs://', 1000 ether, 1000 ether);
  }

  function mockCreateGameCoin(
    string memory name,
    string memory symbol,
    string memory uri,
    uint256 amountGameCoin,
    uint256 amountP12
  ) public returns (address gameCoin) {
    deal(_p12, _coinFactory.getGameDev(_mockGameId), UINT256_MAX);

    vm.startPrank(_mockDeveloper);
    IERC20Upgradeable(_p12).approve(address(_coinFactory), UINT256_MAX);

    gameCoin = _coinFactory.create(name, symbol, uri, _mockGameId, amountGameCoin, amountP12);
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
