// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Swapper} from "../src/uniswap/v2/Swapper.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {UniswapV2Router02} from "../src/uniswap/v2/Router.sol";

import {Token} from "../src/Token.sol";

contract ForkTest is Test {
    Swapper swapper;

    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    UniswapV2Router02 uniswapRouter =
        UniswapV2Router02(payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));

    function setUp() public {
        vm.createSelectFork("https://eth.llamarpc.com"); // Ethereum Mainnet RPC

        swapper = new Swapper();

        deal(dai, address(this), 100 ether); // give 100 DAI
    }

    function test_swapSingleHop() public {
        IERC20(dai).approve(address(swapper), 100 ether);
        swapper.swapExactInputSingleHop(dai, weth, 100 ether, 1, address(this));
    }

    function test_addLiquidty() public {
        Token token1 = new Token("Token1", "TK1");
        Token token2 = new Token("Token2", "TK2");

        token1.approve(address(uniswapRouter), type(uint256).max);
        token2.approve(address(uniswapRouter), type(uint256).max);

        uniswapRouter.addLiquidity(
            address(token1),
            address(token2),
            1000 ether,
            1000 ether,
            900 ether,
            900 ether,
            address(this),
            block.timestamp + 30
        );
        // implement me
    }
}
