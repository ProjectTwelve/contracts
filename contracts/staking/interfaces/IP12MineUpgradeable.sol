// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IP12MineUpgradeable {
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount); // deposit lpToken log
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount); // withdraw lpToken log
  event WithdrawDelay(address indexed user, uint256 indexed pid, uint256 amount, bytes32 newWithdrawId); // delayed unStaking mining log
  event Claim(address indexed user, uint256 amount); // get rewards
  event SetDelayB(uint256 oldDelayB, uint256 newDelayB); // change delayB log
  event SetDelayK(uint256 oldDelayK, uint256 newDelayK); // change delayK log
  event UpdatePool(uint256 pid, address lpToken, uint256 accP12PerShare); // reward change record for unit p12 in each of pool
  event SetReward(uint256 oldP12PerBlock, uint256 newP12PerBlock); // set new reward
  event UpdateLiquidityLimit(address addr, uint256 l, uint256 L, uint256 workingAmount, uint256 poolWorkingAmount);

  function createPool(address lpToken) external; // new pool

  function setDelayK(uint256 delayK) external returns (bool);

  function setDelayB(uint256 delayB) external returns (bool);

  function deposit(address lpToken, uint256 amount) external; // deposit lpToken

  function withdraw(
    address pledger,
    address lpToken,
    bytes32 id
  ) external; // withdraw lpToken

  function withdrawDelay(address lpToken, uint256 amount) external; // delayed unStaking mining

  function addLpTokenInfoForGameCreator(
    address lpToken,
    uint256 amount,
    address gameCoinCreator
  ) external; // add lpToken info for gameCoin creator when first time

  function claim(address lpToken) external; // get pending rewards

  function claimAll() external; // get all pending rewards

  function userCheckpoint(address lpToken) external returns (bool);
}
