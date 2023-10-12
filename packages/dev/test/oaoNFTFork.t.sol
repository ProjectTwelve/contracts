// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/badge/oaoNFT.sol";

contract OaoNFTForkTest is Test {
    oaoNFT private _oaoNFT;

    function setUp() public {
        // vm.createSelectFork("https://rpc.ankr.com/zetachain_evm_athens_testnet");
        // vm.rollFork(1614267);
        // _oaoNFT = oaoNFT(0x69369927AEA310b0423F475330A6Cc7302e2d060);
    }

    function testForkRunWhitelistMint() public {
        // vm.prank();
        // _oaoNFT.whitelistMint(

        // );
    }
}
