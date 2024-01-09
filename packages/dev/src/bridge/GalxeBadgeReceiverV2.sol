// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {IStarNFT} from "src/bridge/interfaces/IStarNFT.sol";
import {IBadgeReceiverV2} from "src/bridge/interfaces/IBadgeReceiverV2.sol";
import {Constant} from "src/libraries/Constant.sol";
import {GalxeBadgeReceiverV2Storage} from "src/bridge/GalxeBadgeReceiverV2Storage.sol";

contract GalxeBadgeReceiverV2 is
    GalxeBadgeReceiverV2Storage,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    IBadgeReceiverV2,
    IERC721ReceiverUpgradeable
{
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner_) public initializer {
        _transferOwnership(owner_);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function sendNFT(address nftAddr, uint256 dstChainId, uint256 tokenId, address receiver) external {
        _sendNFT(nftAddr, dstChainId, tokenId, receiver);
    }

    function sendBatchNFT(address nftAddr, uint256 dstChainId, uint256[] calldata tokenIds, address receiver)
        external
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _sendNFT(nftAddr, dstChainId, tokenId, receiver);
        }
    }

    function releaseNFT(address nftAddr, address user, uint256 tokenId) external onlySigner {
        IERC721Upgradeable(nftAddr).transferFrom(address(this), user, tokenId);
        emit ReleaseNFT(user, tokenId);
    }

    function updateValidNftAddr(address nftAddr, bool valid) external onlyOwner {
        whitelistNFT[nftAddr] = valid;

        emit ValidNftAddrSet(nftAddr, valid);
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

    function _sendNFT(address nftAddr, uint256 dstChainId, uint256 tokenId, address receiver)
        internal
        onlyValidNftAddr(nftAddr)
    {
        if (!allowedDst[dstChainId]) {
            revert DstChainIdIsNotAllowed();
        }

        IERC721Upgradeable(nftAddr).safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 cid = IStarNFT(nftAddr).cid(tokenId);

        emit SendNFT(dstChainId, tokenId, cid, nftAddr, msg.sender, receiver);
    }

    function _checkSigner() internal view {
        if (!signers[msg.sender]) {
            revert NotSigner();
        }
    }

    function _checkValidNftAddr(address addr) internal view {
        // check whitelist nft addr
        if (!whitelistNFT[addr]) {
            revert InvalidNFTAddr();
        }
    }

    modifier onlySigner() {
        _checkSigner();
        _;
    }

    modifier onlyValidNftAddr(address addr) {
        _checkValidNftAddr(addr);
        _;
    }
}
