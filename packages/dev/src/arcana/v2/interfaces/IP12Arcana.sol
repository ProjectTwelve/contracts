// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

interface IP12ArcanaDef {
    enum Activeness {
        InActive,
        Active
    }

    error CannotBeProved();
    error InvalidToken();
    error InvalidProof();

    event RequestParticipant(address user, bytes32 campaign, Activeness activeStatus);
    event SignerUpdate(address indexed signer, bool valid);
    event TokenDisRootSet(address indexed token, bytes32 indexed root);
    event ClaimReward(address indexed token, address indexed user, uint256 amount);
    event Withdrawn(address indexed token, address indexed dst, uint256 amount);
    event PublishGame(uint256 indexed gameId, bool qualified);
}

interface IP12Arcana is IP12ArcanaDef {}
