// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20MissingReturn} from "test/mocks/ERC20/ERC20MissingReturn.sol";
import {Test} from "forge-std/Test.sol";

struct Users {
    // Default admin for all Sablier V2 contracts.
    address payable admin;
    // Impartial user.
    address payable alice;
    // signer
    address payable signer;
}

/// @notice Base test contract with common logic needed by all tests.
abstract contract BaseTest is Test {
    Users internal users;
    ERC20MissingReturn internal usdt;

    function setUp() public virtual {
        users = Users({admin: createUser("admin"), alice: createUser("alice"), signer: createUser("signer")});
        usdt = new ERC20MissingReturn("Tether USD", "USDT", 6);
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({account: user, newBalance: 100 ether});
        return user;
    }
}
