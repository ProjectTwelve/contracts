// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IStarNFT} from "src/interfaces/IStarNFT.sol";
import {IGalxeBadgeReceiver} from "src/interfaces/IGalxeBadgeReceiver.sol";

contract GalxeBadgeReceiver is IGalxeBadgeReceiver, Ownable, IERC721Receiver {
    address public communityBadge;
    mapping(address => bool) public signers;

    constructor(address badge_, address owner_) {
        _setOwner(owner_);
        communityBadge = badge_;
    }

    function sendNFT(uint256 dstChainId, uint256 tokenId, address receiver) external {
        _sendNFT(dstChainId, tokenId, receiver);
    }

    function sendBatchNFT(uint256 dstChainId, uint256[] calldata tokenIds, address receiver) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _sendNFT(dstChainId, tokenId, receiver);
        }
    }

    function releaseNFT(address user, uint256 tokenId) external onlySigner {
        IERC721(communityBadge).transferFrom(address(this), user, tokenId);
        emit ReleaseNFT(user, tokenId);
    }

    function updateSigner(address signer, bool valid) external onlyOwner {
        signers[signer] = valid;

        emit SignerSet(signer, valid);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _sendNFT(uint256 dstChainId, uint256 tokenId, address receiver) internal {
        IERC721(communityBadge).transferFrom(msg.sender, address(this), tokenId);

        uint256 cid = IStarNFT(communityBadge).cid(tokenId);

        emit SendNFT(dstChainId, tokenId, cid, receiver);
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
