// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;
import 'forge-std/Test.sol';
import 'src/coinFactory/P12CoinFactoryUpgradeable.sol';
import 'src/staking/interfaces/IP12MineUpgradeable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

import 'src/staking/interfaces/IGaugeController.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import 'src/coinFactory/interfaces/IP12GameCoin.sol';
import 'src/token/P12Token.sol';
contract CoinFactoryUpgradeableTest is Test{
  P12CoinFactoryUpgradeable public p12CoinFactoryUpgradeable;
  P12Token public p12Token;
  
  function setUp()public{
    p12CoinFactoryUpgradeable = new P12CoinFactoryUpgradeable();
    p12Token = new P12Token('Project Twelve', 'P12', 10000*1e18);
  }

  function testSetDev(address newDev)public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.setDev(newDev);
    assertEq(p12CoinFactoryUpgradeable.dev(),newDev);
  }

  function testSetP12Mine(IP12MineUpgradeable newP12Mine)public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.setP12Mine(newP12Mine);
    assertEq(p12CoinFactoryUpgradeable.p12Mine.address,address(newP12Mine));
  }

  function testSetGaugeController(IGaugeController newGaugeController)public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.setGaugeController(newGaugeController);
    assertEq(p12CoinFactoryUpgradeable.gaugeController.address,address(newGaugeController));
  }


  function testSetP12Token(address NewP12Token)public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.setP12Token(NewP12Token);
    assertEq(p12CoinFactoryUpgradeable.p12(),NewP12Token);
  }

  function testSetUniswapFactory(IUniswapV2Factory NewUniswapFactory)public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.setUniswapFactory(NewUniswapFactory);
    assertEq(p12CoinFactoryUpgradeable.uniswapFactory.address,address(NewUniswapFactory));
  }


  function testSetUniswapRouter(IUniswapV2Router02 newUniswapRouter)public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.setUniswapRouter(newUniswapRouter);
    assertEq(p12CoinFactoryUpgradeable.uniswapRouter.address,address(newUniswapRouter));
  }


  function testRegister(string memory gameId, address developer)public{
    vm.prank(p12CoinFactoryUpgradeable.dev());
    p12CoinFactoryUpgradeable.register(gameId,developer);
    assertEq(p12CoinFactoryUpgradeable.allGames(gameId),developer);
  }


  function testCreate(string memory name,
    string memory symbol,
    string memory gameId,
    string memory gameCoinIconUrl,
    uint96 amountGameCoin,
    uint96 amountP12)public{
      vm.prank(p12Token.owner());
      p12Token.mint(p12CoinFactoryUpgradeable.allGames(gameId), amountP12);
      p12Token.approve(address(p12CoinFactoryUpgradeable),amountP12);
      vm.prank(p12CoinFactoryUpgradeable.allGames(gameId));
      IP12GameCoin gameCoin = p12CoinFactoryUpgradeable.create(name,symbol, gameId, gameCoinIconUrl, amountGameCoin,amountP12);
      assertEq(gameCoin.balanceOf(address(p12CoinFactoryUpgradeable)),amountGameCoin/2);
    }


  function testQueueMintCoin(string memory gameId,
    IP12GameCoin gameCoinAddress,
    uint256 amountGameCoin)public{
    vm.prank(p12CoinFactoryUpgradeable.allGames(gameId));
    bool status = p12CoinFactoryUpgradeable.queueMintCoin(gameId,gameCoinAddress, amountGameCoin);
    assertTrue(status);
  }

  function testExecuteMintCoin(IP12GameCoin gameCoinAddress, bytes32 mintId)public{
    uint256 oldBalance = gameCoinAddress.balanceOf(address(p12CoinFactoryUpgradeable));
    bool status = p12CoinFactoryUpgradeable.executeMintCoin(gameCoinAddress, mintId);
    assertTrue(status);
    uint256 Balance = gameCoinAddress.balanceOf(address(p12CoinFactoryUpgradeable));
    assertGt(Balance,oldBalance);
  }

  function testWithdraw(address userAddress,
    IP12GameCoin gameCoinAddress,
    uint256 amountGameCoin)public{
      vm.prank(p12CoinFactoryUpgradeable.dev());
      p12CoinFactoryUpgradeable.withdraw(userAddress,gameCoinAddress, amountGameCoin);
      uint256 balanceOf = gameCoinAddress.balanceOf(userAddress);
      assertEq(amountGameCoin,balanceOf);
  }

  function testPause()public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.pause();

  }

  function testUnpause()public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.unpause();
  }

  function testSetDelayK(uint256 newDelayK)public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.setDelayK(newDelayK);
    assertEq(p12CoinFactoryUpgradeable.delayK(),newDelayK);
  }

  function testSetDelayB(uint256 newDelayB)public{
    vm.prank(p12CoinFactoryUpgradeable.owner());
    p12CoinFactoryUpgradeable.setDelayB(newDelayB);
    assertEq(p12CoinFactoryUpgradeable.delayB(),newDelayB);
  }

  // function testGetMintFee(IP12GameCoin gameCoinAddress, uint256 amountGameCoin)public{
  //   p12CoinFactoryUpgradeable.getMintFee(gameCoinAddress, amountGameCoin);
  // }


  function testGetMintDelay(IP12GameCoin gameCoinAddress, uint256 amountGameCoin)public{
   uint256 timeA = p12CoinFactoryUpgradeable.getMintDelay(gameCoinAddress, amountGameCoin);
   uint256 timeB = (amountGameCoin * p12CoinFactoryUpgradeable.delayK()) / (IP12GameCoin(gameCoinAddress).totalSupply()) + p12CoinFactoryUpgradeable.delayB();
   assertEq(timeA,timeB);
  }
}