// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UniswapV2Router02} from "./Router.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract Swapper {
    UniswapV2Router02 uniswapRouter =
        UniswapV2Router02(payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));

    function swapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // pull tokens from the user
        // approve the router to spend tokens
        IERC20(tokenIn).approve(address(uniswapRouter), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // execute the swap
        uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            recipient,
            block.timestamp + 30
        );
    }
}
