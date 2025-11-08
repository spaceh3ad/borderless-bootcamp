// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title TokenPermit
/// @notice ERC20 token with gasless approval via EIP-2612 Permit
/// @dev Demonstrates permit functionality allowing approvals without gas
contract TokenPermit is ERC20, ERC20Permit {
    /// @notice Constructor mints initial supply to deployer
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param initialSupply Initial token supply
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) ERC20Permit(name) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mint new tokens - only for testing purposes
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice Example usage of permit for gasless approval
    /// @dev This shows how a relayer can submit permit + transferFrom in one tx
    /// @param owner Token owner granting approval
    /// @param spender Address to approve
    /// @param value Approval amount
    /// @param deadline Permit deadline
    /// @param v ECDSA signature v
    /// @param r ECDSA signature r
    /// @param s ECDSA signature s
    /// @param recipient Final recipient of tokens
    function permitAndTransfer(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address recipient
    ) external {
        // Execute permit (gasless approval)
        permit(owner, spender, value, deadline, v, r, s);

        // Spender can now transfer tokens
        require(spender == msg.sender, "Only spender can transfer");
        transferFrom(owner, recipient, value);
    }
}
