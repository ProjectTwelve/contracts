// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

library CommonError {
  // pass zero address as args
  error ZeroAddressSet();
  // pass zero uint as args;
  error ZeroUintSet();
  // not game developer and no permit to do something
  error NotGameDeveloper(address user, string gameId);
  // not enough p12, pass zero value for p12 amount
  error NotEnoughP12();
  // no permission to do something
  error NoPermission();
}
