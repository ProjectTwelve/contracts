// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBadgeReceiverV2Def {
    error NotSigner();

    error DstChainIdIsNotAllowed();

    error InvalidNFTAddr();

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

    event BurnAndRefund(
        address indexed nftAddr, uint256 indexed cid, uint256 indexed tokenId, uint256 usdRefund, uint256 plRefund
    );

    event ReleaseNFT(address indexed user, uint256 indexed tokenId);

    event SignerSet(address signer, bool valid);

    event ValidNftAddrSet(address nftAddr, bool valid);

    event DstValidSet(uint256 chainId, bool valid);

    event PlRefundSet(uint256[]  cids, uint256[] amounts);

    event UsdRefundSet(uint256[]  cids, uint256[] amounts);
}

interface IBadgeReceiverV2 is IBadgeReceiverV2Def {}
