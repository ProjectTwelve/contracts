// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import {IP12ArcanaDef} from "src/arcana/v2/interfaces/IP12Arcana.sol";

abstract contract P12ArcanaStorage is IP12ArcanaDef {
    uint256 internal _proofAmount;
    uint256 public publicationFee;

    mapping(address => mapping(bytes32 => Activeness)) public activeness;
    mapping(address => bool) internal _isProvedHuman;
    mapping(address => bool) public qualDevs;
    mapping(address => uint256) internal _publishTokenFee;
    mapping(address => bytes32) internal _tokenDisRoot;
    // user => token => amount
    mapping(address => mapping(address => uint256)) internal _claimedAmount;
    mapping(uint256 => bool) public qualGames;

    uint256[41] private __gap;
}
