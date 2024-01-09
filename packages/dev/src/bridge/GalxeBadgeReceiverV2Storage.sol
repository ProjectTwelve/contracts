// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract GalxeBadgeReceiverV2Storage {
    mapping(address => bool) public signers;
    mapping(uint256 => bool) public allowedDst;
    mapping(address => bool) public whitelistNFT;

    uint256[47] private __gap;
}
