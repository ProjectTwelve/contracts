// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.13;

interface IDelegate {
  function delegateType() external view returns (uint256);

  function executeSell(
    address seller,
    address buyer,
    bytes calldata data
  ) external returns (bool);
}
