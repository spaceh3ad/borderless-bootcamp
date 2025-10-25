// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ChainlinkIntegration} from "../src/ChainlinkIntegration.sol";

contract ForkTest is Test {
    LinkToken chainlinkToken =
        LinkToken(0x514910771AF9Ca656af840dff83E8264EcF986CA);
    ChainlinkIntegration chainlinkIntegration;

    function setUp() public {
        vm.createSelectFork("https://eth.llamarpc.com"); // Ethereum Mainnet RPC

        chainlinkIntegration = new ChainlinkIntegration();

        deal(address(chainlinkToken), address(this), 100);
    }

    function test_transferAndCall() public {
        chainlinkToken.transferAndCall(
            address(chainlinkIntegration),
            100,
            "0x"
        );
    }
}

interface LinkToken {
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external returns (bool success);
}
