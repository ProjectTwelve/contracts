// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {BaseTest} from "test/Base.t.sol";
import {GalaxeBadgeReceiverV2} from "src/bridge/GalaxeBadgeReceiverV2.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract GalxeBadgeReceiverV2Test is BaseTest {
    GalaxeBadgeReceiverV2 internal galaxeBadgeReceiverV2;

    function setUp() public override {
        super.setUp();
        deploy();
    }

    function deploy() internal {
        galaxeBadgeReceiverV2 = new GalaxeBadgeReceiverV2(users.admin, address(usdt));
    }
}
