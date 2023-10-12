// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import { console2 } from 'forge-std/console2.sol';
import { Test } from 'forge-std/Test.sol';
import { MockTokenIdDecoder } from 'src/badge/mock/MockTokenIdDecoder.sol';

contract TokenIdDecoderTest is Test {
  MockTokenIdDecoder public _decoder;

  function setUp() public {
    _decoder = new MockTokenIdDecoder();
  }

  function testEncodeId() public {
    assertEq(_decoder.encodeTokenId(0, 1, 1), uint256(0x010000000001));
    assertEq(_decoder.encodeTokenId(1, 1, 1), uint256(0x0100010000000001));
    assertEq(_decoder.encodeTokenId(32, 32, 32), uint256(0x2000200000000020));
  }

  function testDecodeId() public {
    (uint256 rarity, uint256 variety, uint256 incrementId) = _decoder.decodeTokenId(uint256(0x3f6a1b43567898e4));
    assertEq(rarity, uint256(0x3f));
    assertEq(variety, uint256(0x6a1b));
    assertEq(incrementId, uint256(0x43567898e4));
  }
}
