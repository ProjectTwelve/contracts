// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

interface IP12ArcanaDef {
    enum Activeness {
        InActive,
        Active
    }

    error CannotBeProved();
    error InvalidToken();

    event RequestParticipant(address user, bytes32 campaign, Activeness activeStatus);
}

interface IP12Arcana is IP12ArcanaDef {}
