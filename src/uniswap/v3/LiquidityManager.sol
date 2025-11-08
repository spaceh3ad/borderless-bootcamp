// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title Uniswap V3 Liquidity Manager
/// @notice Demonstrates concentrated liquidity and position management
/// @dev Interfaces for Uniswap V3 contracts
interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function liquidity() external view returns (uint128);

    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title LiquidityManager
/// @notice Manages Uniswap V3 concentrated liquidity positions
contract LiquidityManager is IERC721Receiver {
    INonfungiblePositionManager public immutable positionManager;

    event PositionMinted(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event LiquidityIncreased(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event LiquidityDecreased(uint256 indexed tokenId, uint256 amount0, uint256 amount1);
    event FeesCollected(uint256 indexed tokenId, uint256 amount0, uint256 amount1);
    event PositionBurned(uint256 indexed tokenId);

    constructor(address _positionManager) {
        positionManager = INonfungiblePositionManager(_positionManager);
    }

    /// @notice Mint a new concentrated liquidity position
    /// @param token0 Address of token0
    /// @param token1 Address of token1
    /// @param fee Pool fee tier (500 = 0.05%, 3000 = 0.3%, 10000 = 1%)
    /// @param tickLower Lower tick of the position range
    /// @param tickUpper Upper tick of the position range
    /// @param amount0Desired Desired amount of token0
    /// @param amount1Desired Desired amount of token1
    /// @param amount0Min Minimum amount of token0 (slippage protection)
    /// @param amount1Min Minimum amount of token1 (slippage protection)
    function mintNewPosition(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        // Approve position manager to spend tokens
        IERC20(token0).approve(address(positionManager), amount0Desired);
        IERC20(token1).approve(address(positionManager), amount1Desired);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            recipient: address(this),
            deadline: block.timestamp
        });

        (tokenId, liquidity, amount0, amount1) = positionManager.mint(params);

        emit PositionMinted(tokenId, liquidity, amount0, amount1);
    }

    /// @notice Increase liquidity in an existing position
    /// @param tokenId The NFT token ID of the position
    /// @param amount0Desired Desired amount of token0 to add
    /// @param amount1Desired Desired amount of token1 to add
    /// @param amount0Min Minimum amount of token0 (slippage protection)
    /// @param amount1Min Minimum amount of token1 (slippage protection)
    function increaseLiquidity(
        uint256 tokenId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        // Get position info to approve correct tokens
        (,, address token0, address token1,,,,,,,,) = positionManager.positions(tokenId);

        IERC20(token0).approve(address(positionManager), amount0Desired);
        IERC20(token1).approve(address(positionManager), amount1Desired);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
            .IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: block.timestamp
        });

        (liquidity, amount0, amount1) = positionManager.increaseLiquidity(params);

        emit LiquidityIncreased(tokenId, liquidity, amount0, amount1);
    }

    /// @notice Decrease liquidity in an existing position
    /// @param tokenId The NFT token ID of the position
    /// @param liquidity Amount of liquidity to remove
    /// @param amount0Min Minimum amount of token0 (slippage protection)
    /// @param amount1Min Minimum amount of token1 (slippage protection)
    function decreaseLiquidity(uint256 tokenId, uint128 liquidity, uint256 amount0Min, uint256 amount1Min)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
            .DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: block.timestamp
        });

        (amount0, amount1) = positionManager.decreaseLiquidity(params);

        emit LiquidityDecreased(tokenId, amount0, amount1);
    }

    /// @notice Collect accumulated fees from a position
    /// @param tokenId The NFT token ID of the position
    /// @param recipient Address to receive the collected fees
    function collectFees(uint256 tokenId, address recipient) external returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: recipient,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (amount0, amount1) = positionManager.collect(params);

        emit FeesCollected(tokenId, amount0, amount1);
    }

    /// @notice Burn a position NFT (must have 0 liquidity)
    /// @param tokenId The NFT token ID of the position to burn
    function burnPosition(uint256 tokenId) external {
        positionManager.burn(tokenId);
        emit PositionBurned(tokenId);
    }

    /// @notice Get position information
    /// @param tokenId The NFT token ID of the position
    function getPositionInfo(uint256 tokenId)
        external
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        (,, token0, token1, fee, tickLower, tickUpper, liquidity,,, tokensOwed0, tokensOwed1) =
            positionManager.positions(tokenId);
    }

    /// @notice Calculate price from tick
    /// @param tick The tick value
    /// @return price The price as a ratio (1.0001^tick)
    function tickToPrice(int24 tick) public pure returns (uint256 price) {
        // Simplified price calculation
        // Actual: price = 1.0001^tick
        // For demonstration purposes
        if (tick >= 0) {
            price = 1e18 * (10001 ** uint24(tick)) / (10000 ** uint24(tick));
        } else {
            price = 1e18 * (10000 ** uint24(-tick)) / (10001 ** uint24(-tick));
        }
    }

    /// @notice Required to receive NFT positions
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Allow contract to receive ETH
    receive() external payable {}
}
