// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title CounterV1
/// @notice Version 1 of an upgradeable counter using UUPS pattern
/// @dev Demonstrates basic UUPS upgradeability with simple counter logic
/// @custom:oz-upgrades-from TCounterV1
contract TCounterV2 is Initializable, OwnableUpgradeable {
    bool private someBool;
    uint256 public counter;

    event CounterIncremented(uint256 newValue);
    event CounterReset(uint256 oldValue);

    /// @notice Initialize the contract (replaces constructor for upgradeable contracts)
    /// @param initialOwner Address of the contract owner
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    /// @notice Increment the counter
    function increment() external {
        counter++;
        emit CounterIncremented(counter);
    }

    function reset() external onlyOwner {
        uint256 oldValue = counter;
        counter = 0;
        emit CounterReset(oldValue);
    }

    /// @notice Get the contract version
    /// @return Version string
    function version() external pure returns (string memory) {
        return "v2.0.0";
    }
}
