// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {GalxeBadgeReceiverV2Test} from "test/uint/shared/GalxeBadgeReceiverV2.t.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract GBR_OnlyOwner_Test is GalxeBadgeReceiverV2Test {
    modifier onlyOwnerCanCall(address eve) {
        vm.assume(eve != users.admin);
        changePrank(eve);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _;

        changePrank(users.admin);
        _;
    }

    function testFuzz_onlyOwner_UpdateValidNftAddr(address eve) public onlyOwnerCanCall(eve) {
        galxeBadgeReceiverV2.updateValidNftAddr(makeAddr("NFT"), true);
    }

    function testFuzz_onlyOwner_UpdateSigner(address eve) public onlyOwnerCanCall(eve) {
        galxeBadgeReceiverV2.updateSigner(users.signer, true);
    }

    function testFuzz_onlyOwner_UpdateDstValidity(address eve) public onlyOwnerCanCall(eve) {
        galxeBadgeReceiverV2.updateDstValidity(1, true);
    }

    function testFuzz_onlyOwner_UpdateUsdRefund(address eve) public onlyOwnerCanCall(eve) {
        galxeBadgeReceiverV2.updateUsdRefund(new uint256[](1), new uint256[](1));
    }

    function testFuzz_onlyOwner_UpdatePlRefund(address eve) public onlyOwnerCanCall(eve) {
        galxeBadgeReceiverV2.updatePlUsdRefund(new uint256[](1), new uint256[](1));
    }
}
