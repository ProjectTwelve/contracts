// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

interface IDelegate {
  function delegateType() external view returns (uint256);

  function executeSell(
    address seller,
    address buyer,
    bytes calldata data
  ) external returns (bool);
}
