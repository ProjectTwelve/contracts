// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBridgeReceiverDef {
    error NotSigner();

    error DstChainIdIsNotAllowed();

    /// @notice emit bridge galxe badge NFT event
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

    /// @notice emit bridge general NFT event
    /// @dev just emit the bridge NFT request event
    /// @param dstChainId destination dstChainId
    ///  @param tokenId NFT tokenId
    event SendOaoNFT(uint256 indexed dstChainId, uint256 indexed tokenId, address nftAddr, address from, address receiver);

    event ReleaseNFT(address indexed user, uint256 indexed tokenId);

    event SignerSet(address signer, bool valid);

    event DstValidSet(uint256 chainId, bool valid);
}

interface IBridgeReceiver is IBridgeReceiverDef {}
