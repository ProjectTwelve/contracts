// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {BaseTest} from "test/Base.t.sol";
import {GalxeBadgeReceiverV2} from "src/bridge/GalxeBadgeReceiverV2.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract GalxeBadgeReceiverV2Test is BaseTest {
    GalxeBadgeReceiverV2 internal galxeBadgeReceiverV2;

    function setUp() public override {
        super.setUp();
        deploy();
    }

    function deploy() internal {
        galxeBadgeReceiverV2 = new GalxeBadgeReceiverV2(users.admin, address(usdt));
    }
}
