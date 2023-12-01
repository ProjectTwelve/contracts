// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {GalxeBadgeReceiverV2Test} from "test/uint/shared/GalxeBadgeReceiverV2.t.sol";
import {IBadgeReceiverV2Def} from "src/bridge/interfaces/IBadgeReceiverV2.sol";
import {Constant} from "src/libraries/Constant.sol";

contract GBR_V2_Test is GalxeBadgeReceiverV2Test, IBadgeReceiverV2Def {
    function testUpdateValidNftAddr(address nftAddr, bool valid) public {
        changePrank(users.admin);
        assertEq(galxeBadgeReceiverV2.whitelistNFT(nftAddr), false);
        emit ValidNftAddrSet(nftAddr, valid);
        galxeBadgeReceiverV2.updateValidNftAddr(nftAddr, valid);
        assertEq(galxeBadgeReceiverV2.whitelistNFT(nftAddr), valid);
    }

    function testUpdateSigner(address signer, bool valid) public {
        changePrank(users.admin);
        assertEq(galxeBadgeReceiverV2.signers(signer), false);
        emit SignerSet(signer, valid);
        galxeBadgeReceiverV2.updateSigner(signer, valid);
        assertEq(galxeBadgeReceiverV2.signers(signer), valid);
    }

    function testUpdateDstValidity(uint256 chainId, bool valid) public {
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
}
