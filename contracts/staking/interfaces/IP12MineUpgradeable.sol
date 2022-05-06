// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IP12MineUpgradeable {
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount); // deposit lpToken log
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount); // withdraw lpToken log
  event WithdrawDelay(address indexed user, uint256 indexed pid, uint256 amount, bytes32 newWithdrawId); // delayed unStaking mining log
  event Claim(address indexed user, uint256 amount); // get rewards
  event SetDelayB(uint256 oldDelayB ,uint256 newDelayB); // change delayB log
  event SetDelayK(uint256 oldDelayK ,uint256 newDelayK); // change delayK log

  function createPool(address _lpToken, bool _withUpdate) external; // new pool

  function setReward(uint256 _p12PerBlock, bool _withUpdate) external; // set rewards for per block

  function setDelayK(uint256 _delayK) external returns (bool);

  function setDelayB(uint256 _delayB) external returns (bool);

  function getDlpMiningSpeed(address _lpToken) external returns (uint256); // get Mining Speed

  function deposit(address _lpToken, uint256 _amount) external; // deposit lpToken

  function withdraw(
    address pledger,
    address _lpToken,
    bytes32 id
  ) external; // withdraw lpToken

  function withdrawDelay(address _lpToken, uint256 _amount) external; // delayed unStaking mining

  function addLpTokenInfoForGameCreator(address _lpToken, address gameCoinCreator) external; // add lpToken info for gameCoin creator when first time

  function claim(address _lpToken) external; // get pending rewards

  function claimAll() external; // get all pending rewards

  function updatePool(uint256 _pid)external;
  function massUpdatePools() external;
}