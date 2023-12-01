// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";

import {Test} from "forge-std/Test.sol";

import "src/arcana/v1/P12ArcanaPublication.sol";

contract P12ArcanaPublicationTest is Test {
    P12ArcanaPublication _p12ArcanaPublication;
    address _owner = vm.addr(12);
    uint256 _publicationFee = 0.0012 ether;

    function setUp() public {
        _p12ArcanaPublication = new P12ArcanaPublication(_owner);

        // set publication fee
        vm.prank(_owner);
        _p12ArcanaPublication.setPublicationFee(_publicationFee);
    }

    function testPublishGame(address user) public {
        vm.assume(user != address(_p12ArcanaPublication));
        assertEq(_p12ArcanaPublication.qualDevs(user), false);
        assertEq(address(_p12ArcanaPublication).balance, 0);
        mockPublishGame(user);
        assertEq(_p12ArcanaPublication.qualDevs(user), true);
        assertEq(address(_p12ArcanaPublication).balance, _publicationFee);
    }

    function testWithdraw(uint256 balance) public {
        vm.deal(address(_p12ArcanaPublication), balance);

        vm.prank(_owner);
        assertEq(address(_p12ArcanaPublication).balance, balance);
        _p12ArcanaPublication.withdrawFee(_owner);
        assertEq(address(_p12ArcanaPublication).balance, 0);
    }

    function testNotOwnerCannotWithDraw(address caller) public {
        vm.assume(caller != _owner);
        vm.prank(caller);
        vm.expectRevert(Ownable.Unauthorized.selector);
        _p12ArcanaPublication.withdrawFee(caller);
    }

    function mockPublishGame(address user) public {
        hoax(user);

        _p12ArcanaPublication.publishGame{value: _publicationFee}();
    }
}
