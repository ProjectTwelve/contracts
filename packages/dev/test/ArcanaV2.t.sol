// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/arcana/v2/P12ArcanaV2.sol";
import "src/arcana/v2/interfaces/IP12Arcana.sol";
import "src/mock/MockERC20.sol";

contract ArcanaV2Test is Test, IP12ArcanaDef {
    P12ArcanaV2 _arcanaV2;
    MockERC20 _mockErc20;

    address _owner = vm.addr(11);
    address _user = vm.addr(112);

    function setUp() public {
        _mockErc20 = new MockERC20();

        _arcanaV2 = new P12ArcanaV2();

        _arcanaV2.initialize(_owner);
    }

    function testWithdrawErc20() public {
        deal(address(_mockErc20), address(_arcanaV2), 100 ether);
        assertEq(_mockErc20.balanceOf(address(_arcanaV2)), 100 ether);

        vm.expectEmit(true, true, true, true);
        emit Withdrawn(address(_mockErc20), _owner, 100 ether);

        vm.prank(_owner);
        _arcanaV2.withdrawErc20(IERC20(address(_mockErc20)), _owner);

        assertEq(_mockErc20.balanceOf(address(_arcanaV2)), 0 ether);
        assertEq(_mockErc20.balanceOf(_owner), 100 ether);
    }
}
