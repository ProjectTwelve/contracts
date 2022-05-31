// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IGaugeController {
  function addGauge(
    address addr,
    int128 gaugeType,
    uint256 weight
  ) external;
}
