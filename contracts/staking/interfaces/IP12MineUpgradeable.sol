// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '../../token/interfaces/IVotingEscrow.sol';
import './IGaugeController.sol';

interface IP12MineUpgradeable {
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 userAmount, uint256 poolAmount); // deposit lpToken log
  event ExecuteWithdraw(address indexed user, uint256 indexed pid,bytes32 indexed withdrawId, uint256 amount, uint256 userAmount, uint256 poolAmount); // withdraw lpToken log
  event QueueWithdraw(
    address indexed user,
    uint256 pid,
    uint256 indexed amount,
    bytes32 indexed newWithdrawId,
    uint256 unlockTimestamp
  ); // delayed unStaking mining log
  event Claim(address indexed user, uint256 amount); // get rewards
  event SetDelayB(uint256 oldDelayB, uint256 newDelayB); // change delayB log
  event SetDelayK(uint256 oldDelayK, uint256 newDelayK); // change delayK log
  event SetRate(uint256 oldRate, uint256 newRate); // set new rate
  event SetP12Factory(address oldP12Factory, address newP12Factory);
  event SetGaugeController(IGaugeController oldGaugeController, IGaugeController newGaugeController);
  event WithdrawLpTokenEmergency(address lpToken, uint256 amount);

  event Emergency(address executor, uint256 emergencyUnlockTime);
  event Checkpoint(address indexed lpToken, uint256 indexed poolAmount, uint256 accP12PerShare);

  function poolLength() external returns (uint256);

  function getPid(address lpToken) external returns (uint256);

  function getUserLpBalance(address lpToken, address user) external returns (uint256);

  function checkpointAll() external;

  function getWithdrawUnlockTimestamp(address lpToken, uint256 amount) external returns (uint256);

  function withdrawEmergency() external;

  function withdrawLpTokenEmergency(address lpToken) external;

  function withdrawAllLpTokenEmergency() external;

  function emergency() external;

  function createPool(address lpToken) external; // new pool

  function setDelayK(uint256 delayK) external returns (bool);

  function setDelayB(uint256 delayB) external returns (bool);

  function deposit(address lpToken, uint256 amount) external; // deposit lpToken

  function setRate(uint256 newRate) external returns (bool);

  function setP12CoinFactory(address newP12Factory) external;

  function setGaugeController(IGaugeController newGaugeController) external;

  function executeWithdraw(address lpToken, bytes32 id) external; // withdraw lpToken

  function queueWithdraw(address lpToken, uint256 amount) external; // delayed unStaking mining

  function addLpTokenInfoForGameCreator(
    address lpToken,
    uint256 amount,
    address gameCoinCreator
  ) external; // add lpToken info for gameCoin creator when first time

  function claim(address lpToken) external returns (uint256); // get pending rewards

  function claimAll() external returns (uint256); // get all pending rewards

  function checkpoint(address lpToken) external ;
}
