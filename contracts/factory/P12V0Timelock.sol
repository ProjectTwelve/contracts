// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./interfaces/IP12V0TimeLock.sol";

// // Not Used Now

// contract P12V0Timelock is IP12V0Timelock {
//     uint256 public constant GRACE_PERIOD = 14 days;
//     uint256 public constant MINIMUM_DELAY = 2 days;
//     uint256 public constant MAXIMUM_DELAY = 30 days;

//     address public owner;
//     address public pendingAdmin;
//     uint256 public delay;

//     mapping(bytes32 => bool) public queuedTransactions;

//     constructor(address _owner) public {
//         owner = _owner;
//     }

//     modifier onlyOwner() {
//         require(msg.sender == owner);
//         _;
//     }

//     function queueTransaction(
//         address target,
//         uint256 value,
//         string memory signature,
//         bytes memory data,
//         uint256 eta
//     ) public returns (bytes32) {
//         require(
//             msg.sender == owner,
//             "Timelock::queueTransaction: Call must come from admin."
//         );
//         require(
//             eta >= getBlockTimestamp() + delay,
//             "Timelock::queueTransaction: Estimated execution block must satisfy delay."
//         );

//         bytes32 txHash = keccak256(
//             abi.encode(target, value, signature, data, eta)
//         );
//         queuedTransactions[txHash] = true;

//         emit QueueTransaction(txHash, target, value, signature, data, eta);
//         return txHash;
//     }

//     function executeTransaction(
//         address target,
//         uint256 value,
//         string memory signature,
//         bytes memory data,
//         uint256 eta
//     ) public payable returns (bytes memory) {
//         require(
//             msg.sender == owner,
//             "Timelock::executeTransaction: Call must come from admin."
//         );

//         bytes32 txHash = keccak256(
//             abi.encode(target, value, signature, data, eta)
//         );
//         require(
//             queuedTransactions[txHash],
//             "Timelock::executeTransaction: Transaction hasn't been queued."
//         );
//         require(
//             getBlockTimestamp() >= eta,
//             "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
//         );
//         require(
//             getBlockTimestamp() <= eta + GRACE_PERIOD,
//             "Timelock::executeTransaction: Transaction is stale."
//         );

//         queuedTransactions[txHash] = false;

//         bytes memory callData;

//         if (bytes(signature).length == 0) {
//             callData = data;
//         } else {
//             callData = abi.encodePacked(
//                 bytes4(keccak256(bytes(signature))),
//                 data
//             );
//         }

//         // solium-disable-next-line security/no-call-value
//         (bool success, bytes memory returnData) = target.call{value: value}(
//             callData
//         );
//         require(
//             success,
//             "Timelock::executeTransaction: Transaction execution reverted."
//         );

//         emit ExecuteTransaction(txHash, target, value, signature, data, eta);

//         return returnData;
//     }

//     function getBlockTimestamp() internal view returns (uint256) {
//         // solium-disable-next-line security/no-block-members
//         return block.timestamp;
//     }
// }
