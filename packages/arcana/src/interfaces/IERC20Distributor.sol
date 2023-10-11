// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

interface IERC20DistributorDef {
    error ZeroAddressSet();
    error ClaimPeriodNotStartOrEnd();
    error InvalidProof();
    error AlreadyClaimed();
    error ZeroRootSet();
    error InvalidTimestamp();

    event Claim(address indexed claimant, uint256 amount);

    event MerkleRootChanged(bytes32 merkleRoot);
    event ClaimPeriodEndsChanged(uint256 claimPeriodEnds);
    event Withdrawn(address dest, uint256 amount);

}

interface IERC20Distributor is IERC20DistributorDef {}
