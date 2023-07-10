// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;
import 'forge-std/Test.sol';
import 'src/staking/GaugeControllerUpgradeable.sol';
import 'src/token/interfaces/IVotingEscrow.sol';
import 'src/token/VotingEscrow.sol';
import 'src/token/P12Token.sol';

contract GaugeControllerUpgradeableTest is Test {
  GaugeControllerUpgradeable public gaugeControllerUpgradeable;
  VotingEscrow public votingEscrow;
  P12Token public p12Token;
  address _owner = vm.addr(1);

  function setUp(address _p12Token) public {
    gaugeControllerUpgradeable = new GaugeControllerUpgradeable();
    votingEscrow = new VotingEscrow(_owner, _p12Token, 'Vote-escrowed P12', 'veP12');
    p12Token = new P12Token(_owner, 'Project Twelve', 'P12', 10000 * 1e18);
  }

  function testSetVotingEscrow(IVotingEscrow newVotingEscrow) public {
    vm.prank(gaugeControllerUpgradeable.owner());
    gaugeControllerUpgradeable.setVotingEscrow(newVotingEscrow);
    assertEq(gaugeControllerUpgradeable.votingEscrow.address, address(newVotingEscrow));
  }

  function testSetP12CoinFactory(address newP12Factory) public {
    vm.prank(gaugeControllerUpgradeable.owner());
    gaugeControllerUpgradeable.setP12CoinFactory(newP12Factory);
    assertEq(gaugeControllerUpgradeable.p12CoinFactory(), newP12Factory);
  }

  function testGetGaugeTypes(address addr) public {
    int128 typeId = gaugeControllerUpgradeable.getGaugeTypes(addr);
    assertEq(typeId, gaugeControllerUpgradeable.gaugeTypes(addr) - 1);
  }

  function testAddGauge(address addr, int128 gaugeType, uint256 weight) public {
    vm.prank(gaugeControllerUpgradeable.owner());
    gaugeControllerUpgradeable.addGauge(addr, gaugeType, weight);
    assertEq(gaugeControllerUpgradeable.gaugeTypes(addr), gaugeType + 1);
  }

  function testAddType(string memory name, uint256 weight) public {
    vm.prank(gaugeControllerUpgradeable.owner());
    int128 typeId = gaugeControllerUpgradeable.nGauges();
    gaugeControllerUpgradeable.addType(name, weight);
    assertEq(gaugeControllerUpgradeable.gaugeTypeNames(typeId), name);
    assertEq(gaugeControllerUpgradeable.nGauges(), typeId + 1);
  }

  function testChangeTypeWeight(int128 typeId, uint256 weight) public {
    uint256 WEEK = 604800;
    uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;
    gaugeControllerUpgradeable.changeTypeWeight(typeId, weight);
    assertEq(gaugeControllerUpgradeable.pointsTypeWeight(typeId, nextTime), weight);
  }

  // function testChangeGaugeWeight(address addr, uint256 weight)public{
  //   uint256 WEEK = 604800;
  //   uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;
  //   assertEq(gaugeControllerUpgradeable.pointsWeight(addr,nextTime).bias,weight);
  //   assertEq(gaugeControllerUpgradeable.timeWeight(addr),nextTime);
  // }
  function testVoteForGaugeWeights(address gaugeAddr, uint256 userWeight, uint256 value, uint256 unlockTime) public {
    vm.prank(p12Token.owner());
    p12Token.mint(msg.sender, 10 * 1e18);
    p12Token.approve(address(votingEscrow), 10 * 1e18);
    votingEscrow.createLock(value, unlockTime);
    gaugeControllerUpgradeable.voteForGaugeWeights(gaugeAddr, userWeight);
    assertGt(gaugeControllerUpgradeable.lastUserVote(msg.sender, gaugeAddr), block.timestamp);
  }

  function testGetGaugeWeight(address addr) public {
    gaugeControllerUpgradeable.getGaugeWeight(addr);
    //assertEq(gaugeControllerUpgradeable.pointsWeight();
  }

  function testGetTypeWeight(int128 typeId) public {
    uint256 weight = gaugeControllerUpgradeable.getTypeWeight(typeId);
    assertEq(gaugeControllerUpgradeable.pointsTypeWeight(typeId, gaugeControllerUpgradeable.timeTypeWeight(typeId)), weight);
  }

  function testGetTotalWeight() public {
    uint256 weight = gaugeControllerUpgradeable.getTotalWeight();
    assertEq(gaugeControllerUpgradeable.pointsTotal(gaugeControllerUpgradeable.timeTotal()), weight);
  }
  // function testGetWeightsSumPerType(int128 typeId)public{
  //   uint256 bias = gaugeControllerUpgradeable.getWeightsSumPerType(typeId);
  //   assertEq(gaugeControllerUpgradeable.pointsSum(typeId,gaugeControllerUpgradeable.timeSum(typeId)).bias,bias);
  // }
}
