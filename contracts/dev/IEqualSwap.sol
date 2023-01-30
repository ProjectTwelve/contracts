// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

interface IEqualSwap {
  event Swap(address indexed payToken, address indexed forToken, uint256 indexed amount);
  event Withdraw(uint256 indexed erc20Amount, uint256 indexed nativeAmount);
}
