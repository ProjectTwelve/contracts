// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IStarNFT} from "src/bridge/interfaces/IStarNFT.sol";
import {IBadgeReceiverV2} from "src/bridge/interfaces/IBadgeReceiverV2.sol";
import {Constant} from "src/libraries/Constant.sol";

contract GalxeBadgeReceiverV2 is IBadgeReceiverV2, Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;

    mapping(address => bool) public signers;
    mapping(uint256 => bool) public allowedDst;
    mapping(address => bool) public whitelistNFT;
    mapping(uint256 => uint256) public usdRefund;
    mapping(uint256 => uint256) public plRefund;

    address public immutable usdToken;

    constructor(address owner_, address usdToken_) {
        _setOwner(owner_);
        usdToken = usdToken_;
    }

    function burnNFT(address nftAddr, uint256 tokenId) external {
        _burnNFT(nftAddr, tokenId);
    }

    function burnBatchNFT(address nftAddr, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _burnNFT(nftAddr, tokenId);
        }
    }

    function sendNFT(address nftAddr, uint256 dstChainId, uint256 tokenId, address receiver) external {
        _sendNFT(nftAddr, dstChainId, tokenId, receiver);
    }

    function sendBatchNFT(address nftAddr, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _burnNFT(nftAddr, tokenId);
        }
    }

    function releaseNFT(address nftAddr, address user, uint256 tokenId) external onlySigner {
        IERC721(nftAddr).transferFrom(address(this), user, tokenId);
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

    function updateUsdRefund(uint256[] calldata cids, uint256[] calldata usdAmounts) external onlyOwner {
        for (uint256 i = 0; i < cids.length; i++) {
            uint256 cid = cids[i];
            uint256 usdAmount = usdAmounts[i];
            usdRefund[cid] = usdAmount;
        }

        emit UsdRefundSet(cids, usdAmounts);
    }

    function updatePlUsdRefund(uint256[] calldata cids, uint256[] calldata pls) external onlyOwner {
        for (uint256 i = 0; i < cids.length; i++) {
            uint256 cid = cids[i];
            uint256 pl = pls[i];
            plRefund[cid] = pl;
        }

        emit PlRefundSet(cids, pls);
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

        IERC721(nftAddr).safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 cid = IStarNFT(nftAddr).cid(tokenId);

        emit SendNFT(dstChainId, tokenId, cid, nftAddr, msg.sender, receiver);
    }

    function _burnNFT(address nftAddr, uint256 tokenId) internal onlyValidNftAddr(nftAddr) {
        // burn
        IERC721(nftAddr).safeTransferFrom(msg.sender, Constant.BLACK_HOLE_ADDRESS, tokenId);

        uint256 cid = IStarNFT(nftAddr).cid(tokenId);

        // get refund USD
        uint256 refundAmount = usdRefund[cid];

        // refund
        IERC20(usdToken).safeTransfer(msg.sender, refundAmount);

        emit BurnAndRefund(nftAddr, cid, tokenId, refundAmount, plRefund[cid]);
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
