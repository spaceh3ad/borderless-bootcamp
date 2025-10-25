// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Swapper} from "../src/uniswap/v2/Swapper.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract ForkTest is Test {
    Swapper swapper;

    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public {
        vm.createSelectFork("https://eth.llamarpc.com"); // Ethereum Mainnet RPC

        swapper = new Swapper();

        deal(dai, address(this), 100 ether); // give 100 DAI
    }

    function test_swapSingleHop() public {
        IERC20(dai).approve(address(swapper), 100 ether);
        swapper.swapExactInputSingleHop(dai, weth, 100 ether, 1, address(this));
    }
}
