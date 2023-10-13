// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {P12ArcanaStorage} from "./P12ArcanaStorage.sol";
import {IP12Arcana} from "src/arcana/v2/interfaces/IP12Arcana.sol";

contract P12ArcanaV2 is IP12Arcana, UUPSUpgradeable, Ownable2StepUpgradeable, P12ArcanaStorage {
    using AddressUpgradeable for address payable;
    using SafeERC20 for IERC20;

    function initialize(address owner_) public {
        // do not run `__Ownable2Step_init` since we transfer ownership directly
        _transferOwnership(owner_);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function requestParticipant(bytes32 campaign) public {
        activeness[msg.sender][campaign] = Activeness.Active;
        emit RequestParticipant(msg.sender, campaign, Activeness.Active);
    }

    function publishGame() public payable {
        require(msg.value >= publicationFee, "fee not enough");
        qualDevs[msg.sender] = true;
    }

    function publicGame(address token) public {
        uint256 amount = _publishTokenFee[token];
        if (amount == 0) {
            revert InvalidToken();
        }

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        qualDevs[msg.sender] = true;
    }

    function proveToBeHuman() public payable {
        if (msg.value < _proofAmount) {
            revert CannotBeProved();
        }
        _isProvedHuman[msg.sender] = true;
    }

    function setProofAmount(uint256 amount) public onlyOwner {
        _proofAmount = amount;
    }

    function setPublicationTokenFee(address token, uint256 amount) public onlyOwner {
        _publishTokenFee[token] = amount;
    }

    function setPublicationFee(uint256 fee) public onlyOwner {
        publicationFee = fee;
    }

    function withdrawFee(address payable dst) public onlyOwner {
        dst.sendValue(address(this).balance);
        (bool success,) = payable(address(dst)).call{value: (address(this)).balance}("");
        require(success, "withdraw fail");
    }

    function checkIsProvedHuman(address addr) public view returns (bool) {
        return _isProvedHuman[addr];
    }

    function getProofAmount() public view returns (uint256) {
        return _proofAmount;
    }

    function getPublicationTokenFee(address token) public view returns (uint256) {
        return _publishTokenFee[token];
    }
}
