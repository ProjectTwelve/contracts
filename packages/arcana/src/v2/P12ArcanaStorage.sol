// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import {IP12ArcanaDef} from "src/v2/interfaces/IP12Arcana.sol";

abstract contract P12ArcanaStorage is IP12ArcanaDef {
    uint256 internal _proofEthAmount;
    uint256 public publicationFee;

    mapping(address => mapping(bytes32 => Activeness)) public activeness;
    mapping(address => bool) internal _isProvedHuman;
    mapping(address => bool) public qualDevs;
    mapping(address => uint256) public requireAmount;

    uint256[44] private __gap;
}
