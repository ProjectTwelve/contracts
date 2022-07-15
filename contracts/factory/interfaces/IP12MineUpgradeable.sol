// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

interface IP12MineUpgradeable {
  function addLpTokenInfoForGameCreator(
    address pair,
    uint256 liquidity,
    address add
  ) external;
}
