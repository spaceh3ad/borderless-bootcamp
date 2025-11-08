// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Swapper} from "../../../src/uniswap/v2/Swapper.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {UniswapV2Router02} from "../../../src/uniswap/v2/Router.sol";
import {UniswapV2Pair} from "../../../src/uniswap/v2/UniswapV2Pair.sol";

import {Token} from "../../../src/tokens/ERC20/Token.sol";

contract UniswapV2Test is Test {
    Swapper swapper;

    UniswapV2Pair pair =
        UniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);

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

        deal(weth, address(swapper), 1 ether); // give pair 1 WETH

        bob = makeAddr("Bob");
        alice = makeAddr("Alice");

        deal(dai, address(bob), amountBob); // give Bob 100k DAI
        deal(dai, address(alice), amountAlice); // give Alice 100k DAI
    }

    // function test_swapSingleHop() public {
    //     IERC20(dai).approve(address(swapper), 100 ether);
    //     swapper.swapExactInputSingleHop(dai, weth, 100 ether, 1, address(this));
    // }

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
        console.log("\n=== DEMONSTRATING SLIPPAGE ON UNISWAP V2 ===\n");

        address[] memory path = new address[](2);
        path[0] = dai;
        path[1] = weth;

        uint256 aliceSwapAmount = 50_000 ether; // Alice wants to swap 50k DAI
        uint256 bobSwapAmount = 80_000 ether; // Bob will frontrun with 80k DAI

        // STEP 1: Alice gets a quote BEFORE any price movement
        console.log("--- Step 1: Alice gets initial quote ---");
        uint256[] memory aliceQuote = uniswapRouter.getAmountsOut(
            aliceSwapAmount,
            path
        );
        console.log("Alice swapping: %18e DAI", aliceSwapAmount);
        console.log("Expected WETH output: %18e", aliceQuote[1]);

        // STEP 2: Bob frontuns Alice with a large swap (moves the price!)
        console.log("\n--- Step 2: Bob frontruns with large swap ---");
        vm.startPrank(bob);
        uint256[] memory bobResult = _swap(bobSwapAmount, 0, path, bob);
        vm.stopPrank();
        console.log("Bob swapped: %18e DAI", bobSwapAmount);
        console.log("Bob received: %18e WETH", bobResult[1]);
        console.log(">>> PRICE HAS MOVED - SLIPPAGE CREATED <<<");

        // STEP 3: Check what Alice would ACTUALLY get now (after price movement)
        console.log("\n--- Step 3: New quote after price movement ---");
        uint256[] memory aliceNewQuote = uniswapRouter.getAmountsOut(
            aliceSwapAmount,
            path
        );
        console.log("Alice would now get: %18e WETH", aliceNewQuote[1]);

        uint256 slippagePercent = ((aliceQuote[1] - aliceNewQuote[1]) * 10000) /
            aliceQuote[1];
        console.log("Slippage (basis points):", slippagePercent);
        console.log("Slippage percentage:", slippagePercent / 100);

        // STEP 4: Demonstrate slippage protection with tight tolerance
        console.log("\n--- Step 4: Testing with 0.5% slippage tolerance ---");
        uint256 tightTolerance = (aliceQuote[1] * 995) / 1000; // 0.5% tolerance
        console.log("Min amount out (0.5% tolerance): %18e", tightTolerance);
        console.log("Actual amount available: %18e", aliceNewQuote[1]);

        if (aliceNewQuote[1] < tightTolerance) {
            console.log(
                ">>> WOULD REVERT - Slippage exceeds 0.5% tolerance <<<"
            );
            console.log("Slippage protection would save Alice from bad trade!");
        } else {
            console.log(">>> Would succeed - within tolerance <<<");
        }

        // STEP 5: Alice swaps with 5% slippage tolerance (succeeds)
        console.log("\n--- Step 5: Alice swaps with 5% slippage tolerance ---");
        uint256 slippageTolerance = 5; // 5%
        uint256 minAmountOut = (aliceQuote[1] * (100 - slippageTolerance)) /
            100;
        console.log("Min amount out (5% tolerance): %18e", minAmountOut);

        vm.startPrank(alice);
        uint256[] memory aliceResult = _swap(
            aliceSwapAmount,
            minAmountOut,
            path,
            alice
        );
        vm.stopPrank();

        console.log("Alice swapped: %18e DAI", aliceSwapAmount);
        console.log("Alice received: %18e WETH", aliceResult[1]);
        console.log(">>> SWAP SUCCEEDED - Protected with proper slippage <<<");

        // STEP 6: Bob completes the sandwich by swapping WETH back to DAI
        console.log("\n--- Step 6: Bob swaps WETH back to DAI (backrun) ---");
        address[] memory reversePath = new address[](2);
        reversePath[0] = weth;
        reversePath[1] = dai;

        uint256 bobWethBalance = IERC20(weth).balanceOf(bob);
        console.log("Bob's WETH balance: %18e", bobWethBalance);

        vm.startPrank(bob);
        uint256[] memory bobBackrunResult = _swap(
            bobWethBalance,
            0,
            reversePath,
            bob
        );
        vm.stopPrank();

        uint256 bobFinalDai = IERC20(dai).balanceOf(bob);
        console.log("Bob's final DAI balance: %18e", bobFinalDai);
        console.log(">>> BOB COMPLETED SANDWICH ATTACK <<<");

        // STEP 7: Calculate profits and losses
        console.log("\n=== PROFIT & LOSS SUMMARY ===");

        // Bob's profit
        int256 bobProfit = int256(bobFinalDai) - int256(amountBob);
        if (bobProfit > 0) {
            console.log("Bob's profit: %18e DAI", uint256(bobProfit));
            console.log(
                "Bob's profit (USD at $1/DAI): $%18e",
                uint256(bobProfit)
            );
        } else {
            console.log("Bob's loss: %18e DAI", uint256(-bobProfit));
        }

        // Alice's loss in DAI terms
        console.log("\nAlice expected WETH: %18e", aliceQuote[1]);
        console.log("Alice actual WETH: %18e", aliceResult[1]);
        uint256 lossWei = aliceQuote[1] - aliceResult[1];
        console.log("Alice's WETH loss: %18e", lossWei);

        // Convert Alice's loss to DAI value (approximate)
        uint256 aliceLossInDai = (lossWei * bobBackrunResult[1]) /
            bobWethBalance;
        console.log("Alice's loss in DAI terms: %18e", aliceLossInDai);

        console.log(
            "\n>>> Bob extracted MEV by sandwiching Alice's transaction <<<"
        );
    }

    function test_flashloan() public {
        console.log("\n=== UNISWAP V2 FLASH LOAN DEMONSTRATION ===\n");

        // Get available WETH in the pair
        uint256 pairWethBalance = IERC20(weth).balanceOf(address(pair));
        console.log("Pair WETH balance: %18e", pairWethBalance);

        // Borrow 10 WETH via flash loan
        uint256 flashloanAmount = 10 ether;
        console.log("Flash loan amount: %18e WETH", flashloanAmount);

        // Calculate repayment: borrowed * 1000 / 997 (accounts for 0.3% fee)
        // This ensures the constant product formula x * y >= k is maintained
        uint256 repaymentAmount = (flashloanAmount * 1000) / 997 + 1;
        uint256 fee = repaymentAmount - flashloanAmount;
        console.log("Required fee (0.3%%): %18e WETH", fee);
        console.log("Total repayment: %18e WETH", repaymentAmount);

        // Give this contract enough WETH to repay the loan + fee
        // (In reality, you'd use the borrowed funds to make a profit)
        deal(weth, address(this), repaymentAmount);

        // Execute flash loan by calling swap with non-empty data
        console.log("\n--- Executing flash loan ---");
        pair.swap(0, flashloanAmount, address(this), bytes("flashloan"));

        console.log(">>> FLASH LOAN SUCCESSFUL <<<");
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        // Verify this is a flash loan callback
        require(msg.sender == address(pair), "Not pair");
        require(data.length > 0, "Not a flash loan");

        console.log("\n--- Flash loan callback executed ---");
        console.log("Borrowed WETH: %18e", amount1);

        // In a real flash loan arbitrage, you would:
        // 1. Use the borrowed funds for arbitrage/liquidation
        // 2. Make profit
        // 3. Repay the loan + fee from profits

        // Calculate repayment: borrowed * 1000 / 997 + 1
        // This is Uniswap V2's formula to ensure x * y >= k after the flash loan
        uint256 repaymentAmount = (amount1 * 1000) / 997 + 1;
        console.log("Repaying: %18e WETH", repaymentAmount);

        // Repay the flash loan by transferring WETH back to the pair
        IERC20(weth).transfer(address(pair), repaymentAmount);

        console.log(">>> Flash loan repaid <<<");
    }
}
