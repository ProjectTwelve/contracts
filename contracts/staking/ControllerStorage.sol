// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

contract ControllerStorage {
  struct Point {
    uint256 bias;
    uint256 slope;
  }

  struct VotedSlope {
    uint256 slope;
    uint256 power;
    uint256 end;
  }

  struct TmpBiasAndSlope {
    uint256 oldWeightBias;
    uint256 oldWeightSlope;
    uint256 oldSumBias;
    uint256 oldSumSlope;
  }

  struct TmpBias {
    uint256 oldBias;
    uint256 newBias;
  }

  address public admin; // Can and will be a smart contract
  address public futureAdmin; // Can and will be a smart contract

  address public token; // P12 token
  address public votingEscrow; // Voting escrow

  // Gauge parameters
  // All numbers are "fixed point" on the basis of 1e18
  int128 public nGaugeTypes;
  int128 public nGauges;
  mapping(int128 => string) public gaugeTypeNames;

  // Needed for enumeration
  mapping(int128 => address) public gauges;

  // we increment values by 1 prior to storing them here so we can rely on a value
  // of zero as meaning the gauge has not been set
  mapping(address => int128) public gaugeTypes;

  mapping(address => mapping(address => VotedSlope)) public voteUserSlopes; // user -> gauge_addr -> VotedSlope
  mapping(address => uint256) public voteUserPower; // Total vote power used by user
  mapping(address => mapping(address => uint256)) public lastUserVote; // Last user vote's timestamp for each gauge address

  // Past and scheduled points for gauge weight, sum of weights per type, total weight
  // Point is for bias+slope
  // changes_* are for changes in slope
  // time_* are for the last change timestamp
  // timestamps are rounded to whole weeks

  mapping(address => mapping(uint256 => Point)) public pointsWeight; // gauge_addr -> time -> Point
  mapping(address => mapping(uint256 => uint256)) internal changesWeight; // gauge_addr -> time -> slope
  mapping(address => uint256) public timeWeight; // gauge_addr -> last scheduled time (next week)

  mapping(int128 => mapping(uint256 => Point)) public pointsSum; // type_id -> time -> Point
  mapping(int128 => mapping(uint256 => uint256)) internal changesSum; // type_id -> time -> slope
  mapping(int128 => uint256) public timeSum; // type_id -> last scheduled time (next week)

  mapping(uint256 => uint256) public pointsTotal; // time -> total weight
  uint256 public timeTotal; // last scheduled time

  mapping(int128 => mapping(uint256 => uint256)) public pointsTypeWeight; // type_id -> time -> type weight
  mapping(int128 => uint256) public timeTypeWeight; // type_id -> last scheduled time (next week)
}
