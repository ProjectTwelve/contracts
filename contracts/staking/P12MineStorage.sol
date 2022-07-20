// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import './interfaces/IGaugeController.sol';
import './interfaces/IP12RewardVault.sol';
import '../token/interfaces/IP12Token.sol';

contract P12MineStorage {
  address public p12Factory;
  address public p12Token;
  IGaugeController public gaugeController;
  IP12RewardVault public p12RewardVault;

  uint256 public delayK;
  uint256 public delayB;
  uint256 public rate;

  // Info of each pool.
  PoolInfo[] public poolInfos;

  bool public isEmergency;
  uint256 public emergencyUnlockTime;

  uint256[40] private __gap;

  mapping(address => uint256) public lpTokenRegistry;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  mapping(address => uint256) public realizedReward;
  // address=>period=>timestamp
  mapping(address => mapping(uint256 => uint256)) public periodTimestamp;

  // lpToken => id
  mapping(address => bytes32) public preWithdrawIds;
  // lpToken => id=> WithdrawInfo
  mapping(address => mapping(bytes32 => WithdrawInfo)) public withdrawInfos;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of P12s
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (Amount * pool.accP12PerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accP12PerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    address lpToken; // Address of LP token contract.
    uint256 accP12PerShare; // Accumulated P12s per share, times 1e18. See below.
    uint256 amount; // how many lpToken in this pool
    uint256 period;
  }
  // withdraw info
  struct WithdrawInfo {
    address who;
    uint256 amount;
    uint256 unlockTimestamp;
    bool executed;
  }

}
