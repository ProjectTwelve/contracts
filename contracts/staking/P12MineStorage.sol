// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract P12MineStorage {
  uint256 constant ONE = 10**18;

  // Info of each user.
  struct UserInfo {
    uint256 amountOfLpToken; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256 amountOfP12;
    //
    // We do some fancy math here. Basically, any point in time, the amount of P12s
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (amountOfp12 * pool.accP12PerShare) - user.rewardDebt
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
    uint256 p12Total;
    uint256 lastRewardBlock; // Last block number that P12s distribution occurs.
    uint256 accP12PerShare; // Accumulated P12s per share, times 1e18. See below.
  }
  // withdraw info
  struct WithdrawInfo {
    uint256 amount;
    uint256 unlockTimestamp;
    bool executed;
  }

  address public p12Factory;
  address public p12Token;

  address public p12RewardVault;
  uint256 public p12PerBlock;

  // Info of each pool.
  PoolInfo[] public poolInfos;
  mapping(address => uint256) public lpTokenRegistry;

  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  mapping(address => uint256) public realizedReward;

  // The block number when P12 mining starts.
  uint256 public startBlock;

  uint256 public delayK;
  uint256 public delayB;

  // lpToken => id
  mapping(address => bytes32) public preWithdrawIds;
  // lpToken => id=> WithdrawInfo
  mapping(address => mapping(bytes32 => WithdrawInfo)) public withdrawInfos;

  // Sum of all pools p12
  uint256 public totalBalanceOfP12;

  mapping(address => uint256) public totalLpStakedOfEachPool;
}
