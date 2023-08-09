// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface P12CommunityBadgeDef {
    /// @dev msg.sender not minter
    error NotMinter();

    /// @dev minter set event
    event MinterSet(address minter, bool valid);

    /// @notice emit when a new base uri is set
    /// @dev
    /// @param uri new base uri
    event BaseUriSet(string uri);
}

interface IP12CommunityBadge is P12CommunityBadgeDef {}
