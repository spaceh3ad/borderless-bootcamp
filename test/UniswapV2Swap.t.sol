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

    address bob;
    address alice;

    uint256 public amountBob = 100_000 ether;
    uint256 public amountAlice = 100_000 ether;

    UniswapV2Router02 uniswapRouter =
        UniswapV2Router02(payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));

    function setUp() public {
        vm.createSelectFork("https://eth.blockrazor.xyz"); // Ethereum Mainnet RPC

        swapper = new Swapper();

        bob = makeAddr("Bob");
        alice = makeAddr("Alice");

        // deal(dai, address(bob), amountBob); // give 100 DAI
        deal(dai, address(alice), amountAlice); // give 100 DAI
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

    function _swap(
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        address recipient
    ) internal returns (uint256[] memory) {
        IERC20(path[0]).approve(address(uniswapRouter), amountIn);
        return
            uniswapRouter.swapExactTokensForTokens(
                amountIn,
                amountOut,
                path,
                recipient,
                block.timestamp + 30
            );
    }

    function test_howSlippageWorks() public {
        address[] memory path = new address[](2);
        path[0] = dai;
        path[1] = weth;

        // uint256 amountIn = 5000 ether;
        // uint256[] memory amountsOut = uniswapRouter.getAmountsOut(
        //     amountIn,
        //     path
        // );

        // 0%
        // console.log("expected amount out for 10_000 DAI:", amountsOut[1]);
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(
            amountAlice,
            path
        );

        vm.startPrank(bob);
        uint256[] memory swapResult = _swap(
            amountBob,
            0,
            // amountsOut[1],
            path,
            bob
        );
        vm.stopPrank();

        // console.log(
        //     "recevied by alice amount out for 10_000 DAI:",
        //     amountsOut[1]
        // );

        uint256 aliceSlippage = 3;
        uint256 slippageDenominator = 100;

        uint256 minAmountOut = (amountsOut[1] *
            (slippageDenominator - aliceSlippage)) / slippageDenominator;

        vm.startPrank(alice);
        _swap(amountAlice, minAmountOut, path, alice);
        vm.stopPrank();

        vm.startPrank(bob);
        // swap the path
        path[0] = weth;
        path[1] = dai;
        swapResult = _swap(swapResult[1], 0, path, bob);
        vm.stopPrank();

        console.log(
            "Bob received back DAI after swapping WETH:",
            swapResult[1]
        );
    }
}
