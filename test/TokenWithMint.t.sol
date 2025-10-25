// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TokenWithMint} from "../src/TokenWithMint.sol";

contract TokenWithMintTest is Test {
    TokenWithMint token;

    address minter;
    address burner;

    function setUp() public {
        token = new TokenWithMint();

        minter = makeAddr("minter");
        burner = makeAddr("burner");

        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.BURN_ROLE(), burner);
    }

    function test_mintShouldFailIfNotOwner() public {
        vm.prank(address(0x123));
        vm.expectRevert();
        token.mint(address(0x456), 100);
    }

    function test_ownerShouldBeAbleToMint() public {
        vm.prank(minter);
        token.mint(address(this), 1000);
        assertEq(token.balanceOf(address(this)), 1000);
    }

    function test_ownerShouldBeAbleToRevokeRole() public {
        token.revokeRole(token.MINTER_ROLE(), minter);

        vm.prank(minter);
        vm.expectRevert();
        token.mint(address(this), 1000);
    }
}
