// SPDX-License-Identifier: GPL3.0-or-later
pragma solidity 0.8.19;

import { TokenIdDecoder } from 'src/TokenIdDecoder.sol';

contract MockTokenIdDecoder {
  function encodeTokenId(uint256 rarity, uint256 variety, uint256 incrementId) public pure returns (uint256 tokenId) {
    return TokenIdDecoder.encodeTokenId(rarity, variety, incrementId);
  }

  function decodeTokenId(uint256 tokenId) public pure returns (uint256 rarity, uint256 variety, uint256 incrementId) {
    return TokenIdDecoder.decodeTokenId(tokenId);
  }
}
