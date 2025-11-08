// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title SecureSignature
/// @notice Demonstrates secure encoding to prevent hash collisions
/// @dev SECURE: Uses abi.encode instead of abi.encodePacked for dynamic types
contract SecureSignature {
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
    /// @dev SECURE: Uses abi.encode which includes type information and lengths
    /// This prevents hash collisions even with dynamic types
    function executeAction(string memory action, string memory param, bytes memory signature) external {
        // SECURE: abi.encode pads each element and includes length
        // ("ab", "cd") != ("a", "bcd") because lengths are encoded
        bytes32 messageHash = keccak256(abi.encode(action, param));

        if (executedActions[messageHash]) revert AlreadyExecuted();

        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        if (signer != owner) revert InvalidSignature();

        executedActions[messageHash] = true;

        emit ActionExecuted(action, param, msg.sender);
    }

    /// @notice Execute multi-parameter action
    /// @dev SECURE: abi.encode prevents all collision scenarios
    function executeMultiAction(
        string memory action,
        string memory param1,
        string memory param2,
        bytes memory signature
    ) external {
        // SECURE: Each parameter length is encoded separately
        bytes32 messageHash = keccak256(abi.encode(action, param1, param2));

        if (executedActions[messageHash]) revert AlreadyExecuted();

        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        if (signer != owner) revert InvalidSignature();

        executedActions[messageHash] = true;

        emit ActionExecuted(action, string(abi.encodePacked(param1, ",", param2)), msg.sender);
    }

    /// @notice Alternative: Safe use of abi.encodePacked with fixed-size types
    /// @dev When using ONLY fixed-size types, abi.encodePacked is safe
    function executeFixedAction(uint256 actionId, uint256 amount, bytes memory signature) external {
        // SAFE: abi.encodePacked with ONLY fixed-size types (uint256)
        // No collision possible because sizes are fixed
        bytes32 messageHash = keccak256(abi.encodePacked(actionId, amount));

        if (executedActions[messageHash]) revert AlreadyExecuted();

        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedMessageHash, signature);

        if (signer != owner) revert InvalidSignature();

        executedActions[messageHash] = true;

        emit ActionExecuted("fixed", "", msg.sender);
    }

    /// @notice Check if action was executed
    function wasExecuted(string memory action, string memory param) external view returns (bool) {
        bytes32 messageHash = keccak256(abi.encode(action, param));
        return executedActions[messageHash];
    }

    /// @notice Get message hash (for signature generation)
    function getMessageHash(string memory action, string memory param) external pure returns (bytes32) {
        return keccak256(abi.encode(action, param));
    }
}
