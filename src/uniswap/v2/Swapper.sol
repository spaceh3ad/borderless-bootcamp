// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UniswapV2Router02} from "./Router.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract Swapper {
    UniswapV2Router02 uniswapRouter =
        UniswapV2Router02(payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));

    uint256 constant swapAmount = 100 ether; //dai

    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor() {
        IERC20(weth).approve(address(uniswapRouter), type(uint256).max);
    }

    // swap WETH token for DAI
    function distributeReward(address _to) external {
        address[] memory path = new address[](2);
        path[0] = dai;
        path[1] = weth;

        uint256[] memory amountIn = uniswapRouter.getAmountsIn(
            swapAmount,
            path
        );

        path[0] = weth;
        path[1] = dai;

        // execute the swap
        uniswapRouter.swapExactTokensForTokens(
            amountIn[0],
            0, // 0, // onchain
            path,
            _to,
            block.timestamp + 30
        );
    }
}
