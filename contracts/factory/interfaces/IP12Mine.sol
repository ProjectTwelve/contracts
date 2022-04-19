// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IP12Mine {
  function createPool(address _lpToken, bool _withUpdate) external;

  function addLpTokenInfoForGameCreator(address _lpToken, address gameCoinCreator) external;
}
