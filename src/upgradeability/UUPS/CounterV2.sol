// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CounterV1.sol";

/// @custom:oz-upgrades-from CounterV1
contract CounterV2 is CounterV1 {
    bool private someBool;

    function version() external pure override returns (string memory) {
        return "v2.0.0";
    }

    function decrement() external {
        counter--;
    }
}
