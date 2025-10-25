// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {SmartWallet} from "../src/SmartWallet.sol";

import {Token} from "../src/Token.sol";

contract EIP7702Test is Test {
    Token linkToken;
    SmartWallet smartWallet;

    address bob;
    uint256 bobPrivateKey;

    address alice;
    address eve;

    function setUp() public {
        smartWallet = new SmartWallet();

        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vm.prank(bob);
        linkToken = new Token();

        alice = makeAddr("alice");
        eve = makeAddr("eve");

        // https://getfoundry.sh/reference/cheatcodes/sign-delegation/
    }

    function test_batchTransferOnBob() public {
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = eve;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        // vm.expectRevert();
        // vm.prank(bob);
        // SmartWallet(bob).batchTransfer(address(linkToken), recipients, amounts);

        vm.signAndAttachDelegation(address(smartWallet), bobPrivateKey);

        vm.prank(alice);
        SmartWallet(bob).batchTransfer(address(linkToken), recipients, amounts);
    }
}
