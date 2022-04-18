pragma solidity 0.8.2;

interface IP12RewardVault {
  function reward(address to, uint256 amount) external;
}
