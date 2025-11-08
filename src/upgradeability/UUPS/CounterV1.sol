// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    UUPSUpgradeable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title CounterV1
/// @notice Version 1 of an upgradeable counter using UUPS pattern
/// @dev Demonstrates basic UUPS upgradeability with simple counter logic
contract CounterV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public counter;

    event CounterIncremented(uint256 newValue);
    event CounterReset(uint256 oldValue);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the contract (replaces constructor for upgradeable contracts)
    /// @param initialOwner Address of the contract owner
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        counter = 0;
    }

    /// @notice Increment the counter
    function increment() external {
        counter++;
        emit CounterIncremented(counter);
    }

    /// @notice Reset the counter to zero - only owner
    function reset() external onlyOwner {
        uint256 oldValue = counter;
        counter = 0;
        emit CounterReset(oldValue);
    }

    /// @notice Get the current counter value
    /// @return The current counter value
    function getCounter() external view returns (uint256) {
        return counter;
    }

    /// @notice Get the contract version
    /// @return Version string
    function version() external pure virtual returns (string memory) {
        return "v1.0.0";
    }

    /// @notice Authorize upgrade to new implementation - only owner
    /// @param newImplementation Address of the new implementation
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
