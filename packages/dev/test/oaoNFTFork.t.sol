// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/oaoNFT.sol";

contract OaoNFTForkTest is Test {
    oaoNFT private _oaoNFT;

    function setUp() public {
        vm.createSelectFork("https://zetachain-athens-evm.blockpi.network/v1/rpc/public");
        vm.rollFork(1614267);
        _oaoNFT = oaoNFT(0x69369927AEA310b0423F475330A6Cc7302e2d060);
    }

    function testForkRunWhitelistMint() public {
        // vm.prank();
        // _oaoNFT.whitelistMint(

        // );
    }
}
