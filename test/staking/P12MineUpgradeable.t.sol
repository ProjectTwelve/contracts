// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;
import 'forge-std/Test.sol';
import '../../contracts/staking/interfaces/IGaugeController.sol';
import '../../contracts/staking/P12MineUpgradeable.sol';
import '../../contracts/token/P12Token.sol';
import '../../contracts/staking/P12MineStorage.sol';
contract P12MineUpgradeableTest is Test{
  P12MineUpgradeable public p12MineUpgradeable;
  P12Token public p12Token;
  function setUp() public {
    p12MineUpgradeable = new P12MineUpgradeable();
    p12Token = new P12Token('Project Twelve', 'P12', 10000*1e18);
  }

  function testSetP12CoinFactory(address newP12CoinFactory)public{
    vm.prank(p12MineUpgradeable.owner());
    p12MineUpgradeable.setP12CoinFactory(newP12CoinFactory);
    assertEq(p12MineUpgradeable.p12CoinFactory.address,newP12CoinFactory);
  }

  function testSetGaugeController(IGaugeController newGaugeController)public{
    vm.prank(p12MineUpgradeable.owner());  
    p12MineUpgradeable.setGaugeController(newGaugeController);
    assertEq(p12MineUpgradeable.gaugeController.address,address(newGaugeController));

  }
  function testPoolLength()public{
    uint len = p12MineUpgradeable.poolLength();
   // assertEq(p12MineUpgradeable.poolInfos.length,len);
  }
  function testWithdrawEmergency()public{
    vm.prank(p12MineUpgradeable.owner()); 
    p12MineUpgradeable.emergency();
    p12MineUpgradeable.withdrawEmergency();
  }
 
  //function testGetWithdrawUnlockTimestamp(address lpToken, uint256 amount)public{}
  function testGetPid(address lpToken)public{
    uint256 pid = p12MineUpgradeable.getPid(lpToken);
    assertEq(p12MineUpgradeable.lpTokenRegistry(lpToken)-1,pid);
  }
  function testGetUserLpBalance(address lpToken, address user)public{
    uint256 pid = p12MineUpgradeable.getPid(lpToken);
    uint balance  = p12MineUpgradeable.getUserLpBalance(lpToken,user);
    //assertEq(p12MineUpgradeable.userInfo(pid,user).amount,balance);
  }
  function testAddLpTokenInfoForGameCreator(address lpToken,uint256 amount,address gameCoinCreator)public{
    vm.prank(p12MineUpgradeable.p12CoinFactory()); 
    p12MineUpgradeable.addLpTokenInfoForGameCreator(lpToken,amount,gameCoinCreator);
    //assertEq(p12MineUpgradeable.)
  }
  function testEmergency()public{
    vm.prank(p12MineUpgradeable.owner()); 
    p12MineUpgradeable.emergency();
    assertTrue(p12MineUpgradeable.isEmergency());
  }
  function testCreatePool(address lpToken)public{
    vm.prank(p12MineUpgradeable.owner());
    p12MineUpgradeable.createPool(lpToken);
    p12MineUpgradeable.createPool(lpToken);
   // assertEq(p12MineUpgradeable.lpTokenRegistry(lpToken),p12MineUpgradeable.poolInfos.length);
  }
  function testSetDelayK(uint256 newDelayK)public{
    vm.prank(p12MineUpgradeable.owner());
    p12MineUpgradeable.setDelayK(newDelayK);
    assertEq(p12MineUpgradeable.delayK(),newDelayK);
  }
  function testSetDelayB(uint256 newDelayB)public{
    vm.prank(p12MineUpgradeable.owner());
    p12MineUpgradeable.setDelayB(newDelayB);
    assertEq(p12MineUpgradeable.delayB(),newDelayB);
  }
  function testSetRate(uint256 newRate)public{
    vm.prank(p12MineUpgradeable.owner());
    p12MineUpgradeable.setRate(newRate);
    assertEq(p12MineUpgradeable.rate(),newRate);
  }
  
  // function testDeposit(address lpToken, uint256 amount)public{

  // }
  function testQueueWithdraw(address lpToken, uint256 amount)public{
    p12MineUpgradeable.queueWithdraw(lpToken,amount);
    //assertEq(p12MineUpgradeable.)
  }
  function testClaim(address lpToken)public{
    p12MineUpgradeable.claim(lpToken);
    assertGt(p12Token.balanceOf(msg.sender),0);
  }
  function testClaimAll()public{
    p12MineUpgradeable.claimAll();
    assertGt(p12Token.balanceOf(msg.sender),0);
  }
  function testExecuteWithdraw(address lpToken, bytes32 id)public{
    // uint256 pid = p12MineUpgradeable.getPid(lpToken);
    // address _who = p12MineUpgradeable.withdrawInfos(lpToken,id).who;
    // UserInfo memory user = p12MineUpgradeable.userInfo(pid,_who);
    // uint256 stakingBalance = p12MineUpgradeable.user.amount;
    // p12MineUpgradeable.executeWithdraw(lpToken,id);
    // uint256 amount = p12MineUpgradeable.withdrawInfos(lpToken,id).amount;
    // assertEq(p12MineUpgradeable.userInfo(pid,_who).amount,stakingBalance-amount);
  }
  function testWithdrawAllLpTokenEmergency()public{
    vm.prank(p12MineUpgradeable.owner()); 
    p12MineUpgradeable.emergency();
    p12MineUpgradeable.withdrawAllLpTokenEmergency();
    //assertEq(p12MineUpgradeable.userInfo)
  }
  function testWithdrawLpTokenEmergency(address lpToken)public{
    // vm.prank(p12MineUpgradeable.owner()); 
    // p12MineUpgradeable.emergency();
    // p12MineUpgradeable.withdrawLpTokenEmergency(lpToken);
    // uint256 pid = getPid(lpToken);
    // UserInfo memory user = userInfo[pid][msg.sender];
    // assertEq(user.amount,0);
  }

}