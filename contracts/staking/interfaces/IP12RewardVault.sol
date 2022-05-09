// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IP12RewardVault {
  function reward(address to, uint256 amount) external; // send reward
}
