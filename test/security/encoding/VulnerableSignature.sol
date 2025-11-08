// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title VulnerableSignature
/// @notice Demonstrates hash collision vulnerability with abi.encodePacked
/// @dev WARNING: This contract is intentionally vulnerable for educational purposes
/// VULNERABILITY: Uses abi.encodePacked with multiple dynamic types causing hash collisions!
contract VulnerableSignature {
    using ECDSA for bytes32;

    address public owner;
    mapping(bytes32 => bool) public executedActions;

    event ActionExecuted(string action, string param, address executor);

    error InvalidSignature();
    error AlreadyExecuted();

    constructor() {
        owner = msg.sender;
    }

    /// @notice Execute an action with signature verification
    /// @dev VULNERABLE: Hash collision possible with abi.encodePacked!
    /// @param action The action to execute (e.g., "transfer", "approve")
    /// @param param The parameter for the action (e.g., address, amount)
    /// @param signature Owner's signature authorizing the action
    function executeAction(string memory action, string memory param, bytes memory signature) external {
        // VULNERABILITY: abi.encodePacked with multiple dynamic types (strings)
        // This can cause hash collisions!
        // Example: ("ab", "cd") produces same hash as ("a", "bcd")
        bytes32 messageHash = keccak256(abi.encodePacked(action, param));

        // Check if already executed
        if (executedActions[messageHash]) revert AlreadyExecuted();

        // Verify signature
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        if (signer != owner) revert InvalidSignature();

        // Mark as executed
        executedActions[messageHash] = true;

        // Execute action (simplified)
        emit ActionExecuted(action, param, msg.sender);
    }

    /// @notice Execute multi-parameter action
    /// @dev VULNERABLE: Even more collision prone with 3+ dynamic parameters
    function executeMultiAction(
        string memory action,
        string memory param1,
        string memory param2,
        bytes memory signature
    ) external {
        // VULNERABILITY: Multiple dynamic types create many collision opportunities
        // ("a", "b", "c") == ("ab", "", "c") == ("a", "", "bc") etc.
        bytes32 messageHash = keccak256(abi.encodePacked(action, param1, param2));

        if (executedActions[messageHash]) revert AlreadyExecuted();

        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        if (signer != owner) revert InvalidSignature();

        executedActions[messageHash] = true;

        emit ActionExecuted(action, string(abi.encodePacked(param1, ",", param2)), msg.sender);
    }

    /// @notice Check if action was executed
    function wasExecuted(string memory action, string memory param) external view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(action, param));
        return executedActions[messageHash];
    }

    /// @notice Get message hash (for signature generation)
    function getMessageHash(string memory action, string memory param) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(action, param));
    }
}
