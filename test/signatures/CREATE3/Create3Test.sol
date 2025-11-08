// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {
    ICREATE3Factory,
    CREATE3Factory
} from "src/signatures/CREATE3/Create3Factory.sol";
import {Test} from "forge-std/Test.sol";

import {Token} from "src/tokens/ERC20/Token.sol";
import {ERC721Token} from "src/tokens/ERC721/TokenERC721.sol";

import {console} from "forge-std/console.sol";

contract Create3Test is Test {
    CREATE3Factory public factory;
    Token public token;
    ERC721Token public tokenERC721;

    function setUp() public {
        factory = new CREATE3Factory();
    }

    function test_predictDeployedAddress() public {
        bytes32 salt = keccak256(abi.encodePacked("my_salt"));

        bytes memory bytecode = abi.encodePacked(
            type(ERC721Token).creationCode
        );
        address predictedAddress = factory.getDeployed(address(this), salt);

        address deployedAddress = factory.deploy{value: 0}(salt, bytecode);

        console.log("Predicted Address: ", predictedAddress);
        assertEq(predictedAddress, deployedAddress);
    }

    function test_deployTokenWithCreate3() public {
        // bytes32 salt = keccak256(abi.encodePacked("my_salt"));
        console.log("Factory Address: ", address(factory));

        bytes32 salt = 0xfa71b63fc3d8e8c3bc8281e60f85dcc5cc3a10180d92949e3efebca23a8fbd01;

        // bytes memory initCode = type(Token).creationCode;
        // console.logBytes32(keccak256(initCode));

        // return;

        bytes memory bytecode = abi.encodePacked(
            type(Token).creationCode,
            abi.encode("MyToken", "MTK")
        );

        // console.logBytes32(keccak256(bytecode));

        // console.logBytes32(keccak256(bytecode));
        address deployedAddress = factory.deploy{value: 0}(salt, bytecode);

        token = Token(deployedAddress);
        assertEq(address(token), 0x00153922d1A9274cC8B0CE668d821B0Aa65046ed);

        console.log("Deployed Address: ", deployedAddress);
        // assertEq(token.name(), "MyToken");
        // assertEq(token.symbol(), "MTK");
        // assertEq(token.totalSupply(), 1000000000000000000000000);
    }

    function test_deployWithCreate2() public {
        bytes32 salt = 0xedaa6bd81c0ece980adc3382f3fde2cbb5373882702805e16d186e617257eb95;

        // bytes memory bytecode = abi.encodePacked(
        //     type(Token).creationCode,
        //     abi.encode("MyToken", "MTK")
        // );
        // console.logBytes32(keccak256(bytecode));

        token = new Token{salt: salt}("MyToken", "MTK");

        console.log("Deployed Address: ", address(token));
    }
}
