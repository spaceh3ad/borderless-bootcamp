// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {ERC721Token} from "../src/TokenERC721.sol";
import {ERC1155Token} from "../src/TokenERC1155.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        new Token();
        new ERC721Token();
        new ERC1155Token();

        vm.stopBroadcast();
    }
}
