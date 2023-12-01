// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {GalxeBadgeReceiverV2Test} from "test/uint/shared/GalxeBadgeReceiverV2.t.sol";
import {IBadgeReceiverV2Def} from "src/bridge/interfaces/IBadgeReceiverV2.sol";
import {Constant} from "src/libraries/Constant.sol";

contract GBR_V2_Test is GalxeBadgeReceiverV2Test, IBadgeReceiverV2Def {
    function test_UpdateValidNftAddr(address nftAddr, bool valid) public {
        changePrank(users.admin);
        assertEq(galxeBadgeReceiverV2.whitelistNFT(nftAddr), false);
        emit ValidNftAddrSet(nftAddr, valid);
        galxeBadgeReceiverV2.updateValidNftAddr(nftAddr, valid);
        assertEq(galxeBadgeReceiverV2.whitelistNFT(nftAddr), valid);
    }

    function test_UpdateSigner(address signer, bool valid) public {
        changePrank(users.admin);
        assertEq(galxeBadgeReceiverV2.signers(signer), false);
        emit SignerSet(signer, valid);
        galxeBadgeReceiverV2.updateSigner(signer, valid);
        assertEq(galxeBadgeReceiverV2.signers(signer), valid);
    }

    function test_UpdateDstValidity(uint256 chainId, bool valid) public {
        changePrank(users.admin);
        assertEq(galxeBadgeReceiverV2.allowedDst(chainId), false);
        emit DstValidSet(chainId, valid);
        galxeBadgeReceiverV2.updateDstValidity(chainId, valid);
        assertEq(galxeBadgeReceiverV2.allowedDst(chainId), valid);
    }

    function test_SendNFT_Revert_InvalidNFTAddr() public {
        changePrank(users.alice);

        vm.expectRevert(IBadgeReceiverV2Def.InvalidNFTAddr.selector);
        galxeBadgeReceiverV2.sendNFT(address(starNFT), 1, 1, users.alice);
    }

    function test_SendNFT_Revert_DstChainIdIsNotAllowed() public {
        changePrank(users.admin);
        galxeBadgeReceiverV2.updateValidNftAddr(address(starNFT), true);

        changePrank(users.alice);

        vm.expectRevert(IBadgeReceiverV2Def.DstChainIdIsNotAllowed.selector);
        galxeBadgeReceiverV2.sendNFT(address(starNFT), 1, 1, users.alice);
    }

    function test_SendNFT_Successfully() public {
        changePrank(users.admin);
        galxeBadgeReceiverV2.updateValidNftAddr(address(starNFT), true);
        galxeBadgeReceiverV2.updateDstValidity(1, true);

        changePrank(users.alice);

        assertEq(starNFT.ownerOf(1), users.alice);

        // check event emit
        vm.expectEmit(true, true, true, true);
        emit SendNFT(1, 1, 1, address(starNFT), users.alice, users.alice);

        galxeBadgeReceiverV2.sendNFT(address(starNFT), 1, 1, users.alice);

        // check owner change
        assertEq(starNFT.ownerOf(1), address(galxeBadgeReceiverV2));
    }

    function test_SendBatchNFT_Successfully() public {
        changePrank(users.admin);
        galxeBadgeReceiverV2.updateValidNftAddr(address(starNFT), true);
        galxeBadgeReceiverV2.updateDstValidity(1, true);

        changePrank(users.alice);

        assertEq(starNFT.ownerOf(2), users.alice);
        assertEq(starNFT.ownerOf(3), users.alice);
        assertEq(starNFT.ownerOf(4), users.alice);

        // check event emit
        vm.expectEmit(true, true, true, true);
        emit SendNFT(1, 2, 2, address(starNFT), users.alice, users.alice);
        emit SendNFT(1, 3, 2, address(starNFT), users.alice, users.alice);
        emit SendNFT(1, 4, 3, address(starNFT), users.alice, users.alice);

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 2;
        tokenIds[1] = 3;
        tokenIds[2] = 4;

        galxeBadgeReceiverV2.sendBatchNFT(address(starNFT), 1, tokenIds, users.alice);

        // check owner change
        assertEq(starNFT.ownerOf(2), address(galxeBadgeReceiverV2));
        assertEq(starNFT.ownerOf(3), address(galxeBadgeReceiverV2));
        assertEq(starNFT.ownerOf(4), address(galxeBadgeReceiverV2));
    }

    function test_BurnNFT_Revert_InvalidNFTAddr() public {
        changePrank(users.alice);

        vm.expectRevert(IBadgeReceiverV2Def.InvalidNFTAddr.selector);
        galxeBadgeReceiverV2.burnNFT(address(starNFT), 1);
    }

    function test_BurnNFT_Successfully() public {
        changePrank(users.admin);
        galxeBadgeReceiverV2.updateValidNftAddr(address(starNFT), true);
        galxeBadgeReceiverV2.updateDstValidity(1, true);

        changePrank(users.alice);

        assertEq(starNFT.ownerOf(1), users.alice);

        // check event emit
        // vm.expectEmit(true, true, true, true);
        // emit BurnAndRefund(1, 1, 1, address(starNFT), users.alice, users.alice);

        galxeBadgeReceiverV2.burnNFT(address(starNFT), 1);

        // check owner change
        assertEq(starNFT.ownerOf(1), Constant.BLACK_HOLE_ADDRESS);
    }

    function test_BurnBatchNFT_Successfully() public {
        changePrank(users.admin);
        galxeBadgeReceiverV2.updateValidNftAddr(address(starNFT), true);
        galxeBadgeReceiverV2.updateDstValidity(1, true);

        changePrank(users.alice);

        assertEq(starNFT.ownerOf(2), users.alice);
        assertEq(starNFT.ownerOf(3), users.alice);
        assertEq(starNFT.ownerOf(4), users.alice);

        // check event emit
        // vm.expectEmit(true, true, true, true);
        // emit BurnAndRefund(1, 1, 1, address(starNFT), users.alice, users.alice);

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 2;
        tokenIds[1] = 3;
        tokenIds[2] = 4;

        galxeBadgeReceiverV2.burnBatchNFT(address(starNFT), tokenIds);

        // check owner change
        assertEq(starNFT.ownerOf(2), Constant.BLACK_HOLE_ADDRESS);
        assertEq(starNFT.ownerOf(2), Constant.BLACK_HOLE_ADDRESS);
        assertEq(starNFT.ownerOf(2), Constant.BLACK_HOLE_ADDRESS);

        // TODO: check usd balance;
    }
}
