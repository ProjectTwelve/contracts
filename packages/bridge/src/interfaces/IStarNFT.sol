// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IStarNFT {
    function cid(uint256 tokenId) external view returns (uint256);
}
