// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";

contract P12ArcanaPublication is Ownable {
    constructor(address owner_) {
        _initializeOwner(owner_);
    }

    mapping(address => bool) public qualDevs;
    uint256 public publicationFee;

    function publishGame() public payable {
        require(msg.value >= publicationFee, "fee not enough");
        qualDevs[msg.sender] = true;
    }

    function setPublicationFee(uint256 fee) public onlyOwner {
        publicationFee = fee;
    }

    function withdrawFee(address dst) public onlyOwner {
        (bool success,) = payable(address(dst)).call{value: (address(this)).balance}("");
        require(success, "withdraw fail");
    }
}
