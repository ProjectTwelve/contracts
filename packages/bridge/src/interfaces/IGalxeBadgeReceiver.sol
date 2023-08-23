// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGalxeBadgeReceiverDef {
    error NotSigner();

    error DstChainIdIsNotAllowed();

    /// @notice emit bridge NFT event
    /// @dev just emit the bridge NFT request event
    /// @param dstChainId destination dstChainId
    ///  @param tokenId NFT tokenId
    ///  @param cid galxe campaign id

    event SendNFT(
        uint256 indexed dstChainId,
        uint256 indexed tokenId,
        uint256 indexed cid,
        address nftAddr,
        address from,
        address receiver
    );

    event ReleaseNFT(address indexed user, uint256 indexed tokenId);

    event SignerSet(address signer, bool valid);

    event DstValidSet(uint256 chainId, bool valid);
}

interface IGalxeBadgeReceiver is IGalxeBadgeReceiverDef {}
