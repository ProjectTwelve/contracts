// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.19;

import { UUPSUpgradeable } from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import { SafeOwnableUpgradeable } from '@p12/contracts-lib/contracts/access/SafeOwnableUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import { EqualSwapStorage, IERC20Upgradeable } from './EqualSwapStorage.sol';
import { IEqualSwap } from './IEqualSwap.sol';

contract EqualSwap is IEqualSwap, EqualSwapStorage, SafeOwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
  function initialize(IERC20Upgradeable erc20_, address owner_) public initializer {
    erc20 = erc20_;
    __Ownable_init(owner_);
    __ReentrancyGuard_init();
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  // receive native token
  receive() external payable {}

  /**
   * @dev use native token to get erc20 token
   */
  function swapNativeForERC20() external payable {
    uint256 amount = msg.value;
    erc20.transfer(msg.sender, msg.value);
    emit Swap(address(0), address(erc20), amount);
  }

  /**
   * @dev use erc20 token to get native token
   * @dev use nonReentrant to defend reentry
   */
  function swapERC20ForNative(uint256 amount) external nonReentrant {
    erc20.transferFrom(msg.sender, address(this), amount);
    payable(msg.sender).transfer(amount);

    emit Swap(address(erc20), address(0), amount);
  }

  /**
   * @dev withdraw all native token and erc20
   */
  function withdraw() external onlyOwner {
    uint256 erc20Amount = erc20.balanceOf(address(this));
    uint256 nativeAmount = address(this).balance;
    erc20.transfer(msg.sender, erc20Amount);
    payable(msg.sender).transfer(nativeAmount);
    emit Withdraw(erc20Amount, nativeAmount);
  }
}
