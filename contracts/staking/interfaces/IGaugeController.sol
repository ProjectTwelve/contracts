// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '../../token/interfaces/IVotingEscrow.sol';

interface IGaugeController {
  event CommitOwnership(address admin);

  event ApplyOwnership(address admin);

  event AddType(string, int128 typeId);

  event NewTypeWeight(int128 typeId, uint256 time, uint256 weight, uint256 totalWeight);

  event NewGaugeWeight(address gaugeAddress, uint256 time, uint256 weight, uint256 totalWeight);

  event VoteForGauge(uint256 time, address user, address gaugeAddress, uint256 weight);

  event NewGauge(address addr, int128 gaugeType, uint256 weight);

  event SetVotingEscrow(IVotingEscrow oldVotingEscrow, IVotingEscrow newVotingEscrow);

  event SetP12Factory(address oldP12Factory, address newP12Factory);

  function checkpointGauge(address addr) external;

  function gaugeRelativeWeight(address lpToken, uint256 time) external returns (uint256);

  function getGaugeWeight(address addr) external returns (uint256);

  function getTypeWeight(int128 typeId) external returns (uint256);

  function getTotalWeight() external returns (uint256);

  function getWeightsSumPerType(int128 typeId) external returns (uint256);

  function addGauge(
    address addr,
    int128 gaugeType,
    uint256 weight
  ) external;

  function addType(string memory name, uint256 weight) external;

  function setVotingEscrow(IVotingEscrow newVotingEscrow) external;

  function setP12Factory(address newP12Factory) external;
}
