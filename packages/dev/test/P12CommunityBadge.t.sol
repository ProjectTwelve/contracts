// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {P12CommunityBadge} from "src/badge/P12CommunityBadge.sol";

contract P12CommunityBadgeTest is Test {
    address _owner = vm.addr(11);
    address _minter = vm.addr(12);
    address _user = vm.addr(13);
    P12CommunityBadge _badge;

    function setUp() public {
        _badge = new P12CommunityBadge(_owner, "P12 Badge Collection", "P12Badge");
    }

    function testTokenURI() public {
        string memory baseURI = "https://example.com/";
        vm.prank(_owner);
        _badge.setBaseUri(baseURI);
        assertEq(_badge.tokenURI(1), "https://example.com/1.json");
    }
}
