// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IP12Asset {
  function create(uint256, string calldata) external returns (uint256);

  function mint(
    address,
    uint256,
    uint256,
    bytes memory
  ) external;

  function setContractURI(string calldata) external;
}
