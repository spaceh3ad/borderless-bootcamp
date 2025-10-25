// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "../src/merkle/Airdrop.sol";

contract AirdropTest is Test {
    address bob;
    address deployer;

    Airdrop airdrop;

    function setUp() public {
        bob = makeAddr("bob");
        deployer = makeAddr("deployer");

        vm.prank(deployer);
        airdrop = new Airdrop(
            0x966a116134c0daa752572297292124fb903a8fa852cab362675a6721eafb0c87
        );
    }

    function test_verifyProof() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[
            0
        ] = 0x59493282d16742ccb02c832c21defe4008ab4749ed32b0e948aab5515a153b3c;
        proof[
            1
        ] = 0xb7277a2009c4afc262e42323e26a4aae0f0a2f52f8911e9476ac1b59ebcb7ac1;

        vm.prank(bob);
        bool isValid = airdrop.claim(
            100000000,
            0xabc1230000000000000000000000000000000000000000000000000000000001,
            0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
            proof
        );
        assertTrue(isValid);
    }
}
