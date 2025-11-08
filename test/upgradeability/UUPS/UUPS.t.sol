// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CounterV1} from "src/upgradeability/UUPS/CounterV1.sol";
import {CounterV2} from "src/upgradeability/UUPS/CounterV2.sol";

import {Test} from "forge-std/Test.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSTest is Test {
    CounterV1 public counterV1;

    function setUp() public {}

    function test_deployUUPS() public {
        // Deploy implementation
        CounterV1 implementation = new CounterV1();

        // Deploy proxy
        address proxy = address(
            new ERC1967Proxy(
                address(implementation),
                abi.encodeCall(CounterV1.initialize, (address(this)))
            )
        );

        CounterV2 implementationV2 = new CounterV2();

        CounterV1(proxy).increment();
        CounterV1(proxy).version();
        CounterV1(proxy).upgradeToAndCall(address(implementationV2), "");
        CounterV2(proxy).decrement();
        CounterV2(proxy).version();
    }

    function test_deployUUPSFoundryUpgrades() public {
        // Deploy proxy pointing to V1
        address proxy = Upgrades.deployUUPSProxy(
            "CounterV1.sol",
            abi.encodeCall(CounterV1.initialize, (address(this)))
        );

        assertEq(CounterV1(proxy).counter(), 0);
        CounterV1(proxy).increment();
        assertEq(CounterV1(proxy).counter(), 1);
        assertEq(CounterV1(proxy).version(), "v1.0.0");

        // upgrade to V2
        Upgrades.upgradeProxy(proxy, "CounterV2.sol", "");

        CounterV2(proxy).decrement();
        assertEq(CounterV2(proxy).counter(), 0);
        assertEq(CounterV2(proxy).version(), "v2.0.0");
    }
}
