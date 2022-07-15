// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

interface IGaugeController {
  function addGauge(
    address pair,
    int128 gaugeType,
    uint256 weight
  ) external;
}
