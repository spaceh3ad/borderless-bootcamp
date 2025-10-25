// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Token, TokenHandler} from "../src/Token.sol";
import {SigUtils} from "./SigUtils.sol";

contract TokenTest is Test {
    Token public token;
    TokenHandler public tokenHandler;
    SigUtils public sigUtils;

    address deployer;
    uint256 deployerPrivateKey;

    function setUp() public {
        (deployer, deployerPrivateKey) = makeAddrAndKey("deployer");

        vm.prank(deployer);
        token = new Token("MyToken", "MTK");

        tokenHandler = new TokenHandler();

        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());
    }

    function permitSignature(
        uint256 amount,
        uint256 deadline
    ) internal returns (uint8 v, bytes32 r, bytes32 s) {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: deployer,
            spender: address(tokenHandler),
            value: amount,
            nonce: token.nonces(deployer),
            deadline: deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (v, r, s) = vm.sign(deployerPrivateKey, digest);
    }

    function test_transferHandler() public {
        uint256 amount = 5000;
        uint256 deadline = block.timestamp + 1 hours;

        (uint8 v, bytes32 r, bytes32 s) = permitSignature(amount, deadline);

        vm.prank(deployer);
        tokenHandler.handleToken(address(token), 5000, deadline, v, r, s); // 2nd call
    }
}
