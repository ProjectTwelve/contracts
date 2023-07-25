// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

interface IRegistry {
  function addressRegistry(bytes32 key) external view returns (address);

  function registerAddress(bytes32 key, address addr) external;
}
