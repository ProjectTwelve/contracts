// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20Distributor} from "src/v1/interfaces/IERC20Distributor.sol";

contract ERC20Distributor is IERC20Distributor, Ownable2Step {
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    bytes32 public merkleRoot;
    uint256 public claimPeriodEnds;
    BitMaps.BitMap private claimed;

    constructor(address owner_, IERC20 rewardToken_) {
        _transferOwnership(owner_);
        rewardToken = rewardToken_;
    }

    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (block.timestamp >= claimPeriodEnds) {
            revert ClaimPeriodNotStartOrEnd();
        }

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, amount)))
        );
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);

        if (!valid) {
            revert InvalidProof();
        }
        if (isClaimed(_msgSender())) {
            revert AlreadyClaimed();
        }

        claimed.set(uint160(_msgSender()));
        rewardToken.safeTransfer(_msgSender(),amount);
        emit Claim(msg.sender, amount);
    }

    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param user The index into the merkle tree.
     */
    function isClaimed(address user) public view returns (bool) {
        return claimed.get(uint256(uint160(user)));
    }

    /**
     * @dev Sets the merkle root.
     * @notice allow set twice here
     * @param newMerkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        if (newMerkleRoot == bytes32(0)) {
            revert ZeroRootSet();
        }
        merkleRoot = newMerkleRoot;
        emit MerkleRootChanged(merkleRoot);
    }

    /**
     * @dev Sets the claim period ends.
     * @param claimPeriodEnds_ The merkle root to set.
     */
    function setClaimPeriodEnds(uint256 claimPeriodEnds_) external onlyOwner {
        if (claimPeriodEnds_ <= block.timestamp) {
            revert InvalidTimestamp();
        }
        claimPeriodEnds = claimPeriodEnds_;
        emit ClaimPeriodEndsChanged(claimPeriodEnds);
    }

    /**
     * @dev withdraw remaining native tokens.
     */
    function withdraw(address to) external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(to,balance);
        emit Withdrawn(to, balance);
    }

}
