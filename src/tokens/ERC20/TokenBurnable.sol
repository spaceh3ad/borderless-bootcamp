// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title TokenBurnable
/// @notice ERC20 token with burn functionality
/// @dev Demonstrates token burning for deflationary mechanics
contract TokenBurnable is ERC20, ERC20Burnable {
    event TokensBurned(address indexed burner, uint256 amount);

    /// @notice Constructor mints initial supply to deployer
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param initialSupply Initial token supply
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mint new tokens - only for testing purposes
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice Burn tokens with event emission
    /// @param amount Amount to burn
    /// @dev Overrides burn to add custom event
    function burn(uint256 amount) public override {
        super.burn(amount);
        emit TokensBurned(msg.sender, amount);
    }

    /// @notice Burn tokens from another address (with approval)
    /// @param account Account to burn from
    /// @param amount Amount to burn
    /// @dev Overrides burnFrom to add custom event
    function burnFrom(address account, uint256 amount) public override {
        super.burnFrom(account, amount);
        emit TokensBurned(account, amount);
    }
}
