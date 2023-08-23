// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IStarNFT} from "src/interfaces/IStarNFT.sol";
import {IGalxeBadgeReceiver} from "src/interfaces/IGalxeBadgeReceiver.sol";

contract GalxeBadgeReceiver is IGalxeBadgeReceiver, Ownable, IERC721Receiver {
    mapping(address => bool) public signers;
    mapping(uint256 => bool) public allowedDst;

    constructor(address owner_) {
        _setOwner(owner_);
    }

    function sendNFT(address nftAddr, uint256 dstChainId, uint256 tokenId, address from, address receiver) external {
        _sendNFT(nftAddr, dstChainId, tokenId, from, receiver);
    }

    function sendBatchNFT(
        address nftAddr,
        uint256 dstChainId,
        uint256[] calldata tokenIds,
        address from,
        address receiver
    ) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _sendNFT(nftAddr, dstChainId, tokenId, from, receiver);
        }
    }

    function releaseNFT(address nftAddr, address user, uint256 tokenId) external onlySigner {
        IERC721(nftAddr).transferFrom(address(this), user, tokenId);
        emit ReleaseNFT(user, tokenId);
    }

    function updateSigner(address signer, bool valid) external onlyOwner {
        signers[signer] = valid;

        emit SignerSet(signer, valid);
    }

    function updateDstValidity(uint256 dstChainId, bool valid) external onlyOwner {
        allowedDst[dstChainId] = valid;

        emit DstValidSet(dstChainId, valid);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _sendNFT(address nftAddr, uint256 dstChainId, uint256 tokenId, address from, address receiver) internal {
        if (!allowedDst[dstChainId]) {
            revert DstChainIdIsNotAllowed();
        }
        IERC721(nftAddr).transferFrom(from, address(this), tokenId);

        uint256 cid = IStarNFT(nftAddr).cid(tokenId);

        emit SendNFT(dstChainId, tokenId, cid, from, receiver);
    }

    function _checkSigner() internal view {
        if (!signers[msg.sender]) {
            revert NotSigner();
        }
    }

    modifier onlySigner() {
        _checkSigner();
        _;
    }
}
