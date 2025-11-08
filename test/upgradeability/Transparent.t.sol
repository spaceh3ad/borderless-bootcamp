// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Test} from "forge-std/Test.sol";
import {TCounterV1} from "src/upgradeability/transparent/TCounterV1.sol";
import {TCounterV2} from "src/upgradeability/transparent/TCounterV2.sol";
import {Upgrades} from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import {
    ProxyAdmin
} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {
    ERC1967Utils
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract TransparentTest is Test {
    TCounterV1 public counterV1;
    TCounterV2 public counterV2;
    address public proxyAddress;

    address bob;

    function setUp() public {
        bob = address(0xB0B);
        // Deploy implementation V1
    }

    function test_deployTransparentRaw() public {
        TCounterV1 implV1 = new TCounterV1();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implV1),
            bob,
            abi.encodeCall(TCounterV1.initialize, (bob))
        );

        assertEq(TCounterV1(address(proxy)).owner(), bob);
        assertEq(TCounterV1(address(proxy)).counter(), 0);
        TCounterV1(address(proxy)).increment();
        TCounterV1(address(proxy)).increment();

        bytes32 ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

        address proxyAdminAddr = address(
            uint160(uint256(vm.load(address(proxy), ADMIN_SLOT)))
        );

        vm.startPrank(bob);
        ProxyAdmin(proxyAdminAddr).upgradeAndCall(
            ITransparentUpgradeableProxy(address(proxy)),
            address(new TCounterV2()),
            "" // no extra init
        );
        vm.stopPrank();
        assertEq(TCounterV1(address(proxy)).counter(), 2);
        assertEq(TCounterV2(address(proxy)).version(), "v2.0.0");
    }

    function test_transparentDeploy() public {
        // Deploy proxy pointing to V1
        address proxy = Upgrades.deployTransparentProxy(
            "TCounterV1.sol",
            bob,
            abi.encodeCall(TCounterV1.initialize, (bob))
        );

        // Wrap proxy with TCounterV1 interface

        assertEq(TCounterV1(proxy).owner(), bob);
        assertEq(TCounterV1(proxy).counter(), 0);
        TCounterV1(proxy).increment();
        TCounterV1(proxy).increment();
        // assertEq(TCounterV1(proxy).counter(), 1);
        assertEq(TCounterV2(proxy).version(), "v1.0.0");

        // upgrade to V2
        vm.startPrank(bob);
        Upgrades.upgradeProxy(proxy, "TCounterV2.sol", "");

        TCounterV2(proxy).reset();
        vm.stopPrank();

        assertEq(TCounterV2(proxy).counter(), 0);
        assertEq(TCounterV2(proxy).version(), "v2.0.0");
    }
}
