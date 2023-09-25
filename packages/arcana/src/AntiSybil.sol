// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract AntiSybilStorge {
    uint256 internal _proofEthAmount;
    mapping(address => bool) internal _isProvedHuman;
    uint256[48] private __gap;
}

interface IAntiSybil {
    error CannotBeProved();
}

contract AntiSybil is IAntiSybil, UUPSUpgradeable, Ownable2StepUpgradeable, AntiSybilStorge {
    using AddressUpgradeable for address payable;

    function initialize(address owner_) public {
        // do not run `__Ownable2Step_init` since we transfer ownership directly
        _transferOwnership(owner_);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function proveToBeHuman() public payable {
        if (msg.value <= _proofEthAmount) {
            revert CannotBeProved();
        }
        _isProvedHuman[msg.sender] = true;
    }

    function setProofEthAmount(uint256 amount) public onlyOwner {
        _proofEthAmount = amount;
    }

    function withDrawNativeToken(address payable recipient) public onlyOwner {
        recipient.sendValue(address(this).balance);
    }

    function checkIsProvedHuman(address addr) public view returns (bool) {
        return _isProvedHuman[addr];
    }

    function getProofEthAmount() public view returns (uint256) {
        return _proofEthAmount;
    }
}
