// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Uniswap V3 Swap Router
/// @notice Demonstrates token swaps on Uniswap V3 with exact input/output
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title SwapRouter
/// @notice Wrapper for Uniswap V3 swap operations
contract SwapRouter {
    ISwapRouter public immutable swapRouter;

    event SwapExecuted(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _swapRouter) {
        swapRouter = ISwapRouter(_swapRouter);
    }

    /// @notice Swap exact input for output (single hop)
    /// @param tokenIn Input token address
    /// @param tokenOut Output token address
    /// @param fee Pool fee tier (500, 3000, or 10000)
    /// @param amountIn Amount of input token
    /// @param amountOutMinimum Minimum output amount (slippage protection)
    /// @param recipient Address to receive output tokens
    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient
    ) external returns (uint256 amountOut) {
        // Approve router to spend tokens
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0 // No price limit
        });

        amountOut = swapRouter.exactInputSingle(params);

        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Swap exact input for output (multi-hop)
    /// @param path Encoded path of tokens and fees
    /// @param amountIn Amount of input token
    /// @param amountOutMinimum Minimum output amount
    /// @param recipient Address to receive output tokens
    function swapExactInputMultihop(bytes memory path, uint256 amountIn, uint256 amountOutMinimum, address recipient)
        external
        returns (uint256 amountOut)
    {
        // Extract first token from path for approval
        address tokenIn;
        assembly {
            tokenIn := mload(add(path, 32))
        }

        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: recipient,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum
        });

        amountOut = swapRouter.exactInput(params);
    }

    /// @notice Swap for exact output (single hop)
    /// @param tokenIn Input token address
    /// @param tokenOut Output token address
    /// @param fee Pool fee tier
    /// @param amountOut Exact amount of output token desired
    /// @param amountInMaximum Maximum input amount (slippage protection)
    /// @param recipient Address to receive output tokens
    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient
    ) external returns (uint256 amountIn) {
        IERC20(tokenIn).approve(address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: block.timestamp,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum,
            sqrtPriceLimitX96: 0
        });

        amountIn = swapRouter.exactOutputSingle(params);

        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Encode path for multi-hop swaps
    /// @dev Format: token0 | fee0 | token1 | fee1 | token2
    /// @param tokens Array of token addresses
    /// @param fees Array of pool fees
    function encodePath(address[] memory tokens, uint24[] memory fees) public pure returns (bytes memory path) {
        require(tokens.length == fees.length + 1, "Invalid path");

        path = abi.encodePacked(tokens[0]);
        for (uint256 i = 0; i < fees.length; i++) {
            path = abi.encodePacked(path, fees[i], tokens[i + 1]);
        }
    }
}
