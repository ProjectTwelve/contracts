// SPDX-License-Identifier: GPL3.0-or-later
pragma solidity 0.8.19;

library TokenIdDecoder {
  function encodeTokenId(uint256 rarity, uint256 variety, uint256 incrementId) internal pure returns (uint256 tokenId) {
    tokenId = (rarity << 56) + (variety << 40) + incrementId;
  }

  function decodeTokenId(uint256 tokenId) internal pure returns (uint256 rarity, uint256 variety, uint256 incrementId) {
    rarity = tokenId >> 56;
    variety = (tokenId & (0x00ffff << 40)) >> 40;
    incrementId = uint256(tokenId & type(uint40).max);
  }
}
