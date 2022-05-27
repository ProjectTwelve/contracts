// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

interface IP12Mine {
  function createPool(address _lpToken) external;

  function addLpTokenInfoForGameCreator(
    address _lpToken,
    uint256 value,
    address gameCoinCreator
  ) external;
}
