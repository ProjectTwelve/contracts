// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

interface IP12Mine {
  function createPool(address _lpToken, bool _withUpdate) external;

  function addLpTokenInfoForGameCreator(address _lpToken, address gameCoinCreator) external;
}
