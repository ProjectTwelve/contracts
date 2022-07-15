// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

interface IP12RewardVault {
  function reward(address to, uint256 amount) external; // send reward

  function withdrawEmergency(address to) external;

  event WithdrawEmergency(address p12Token,uint256 amount);
}
