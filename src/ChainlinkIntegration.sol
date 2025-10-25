// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";

contract ChainlinkIntegration {
    function onTokenTransfer(
        address _sender,
        uint _value,
        bytes calldata _data
    ) public pure {
        console.log("onTokenTransfer called INTEGERATION");
    }
    // Chainlink integration code would go here
}
