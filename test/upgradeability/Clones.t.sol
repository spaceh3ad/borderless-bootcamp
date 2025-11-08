// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Test} from "forge-std/Test.sol";
import {FarmFactory, Farm} from "../../src/upgradeability/clones/Factory.sol";

contract FactoryTest is Test {
    FarmFactory factory;
    Farm farm;

    function setUp() public {
        factory = new FarmFactory();

        // setting the impl
        farm = new Farm();
    }

    function test_deployRawFarm() public {
        for (uint256 index = 0; index < 100; index++) {
            address farmAddress = factory.createFarm();
            assertTrue(
                farmAddress != address(0),
                "Farm address should not be zero"
            );
        }
    }

    function test_cloneFarm() public {
        factory.setFarmImplementation(address(farm));

        for (uint256 index = 0; index < 100; index++) {
            address farmAddress = factory.cloneFarm();
            assertTrue(
                farmAddress != address(0),
                "Cloned Farm address should not be zero"
            );
        }
    }
}
