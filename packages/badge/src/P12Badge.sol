// SPDX-License-Identifier: GPL3.0-or-later
pragma solidity 0.8.19;

import { ERC721 } from 'solady/tokens/ERC721.sol';

/**
 * @dev p12 badge has five rarity, thery are orange, purple, blue, green, white
 * @dev for gas efficency, we would encode the rarity in tokenId.
 * @dev we place tokenId in the following ways:
 * @dev uint216 for reserve, uint8 for rarity, uint40 for increment id
 */

contract P12Badge is ERC721 {
  string private _name;
  string private _symbol;
  mapping(uint256 => string) private _uri;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      ERC721 METADATA                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return _uri[tokenId];
  }
}
